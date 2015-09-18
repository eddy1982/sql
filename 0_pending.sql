
-- ███████╗██████╗ ██████╗ ██╗   ██╗    ███████╗ ██████╗ ██╗     
-- ██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝    ██╔════╝██╔═══██╗██║     
-- █████╗  ██║  ██║██║  ██║ ╚████╔╝     ███████╗██║   ██║██║     
-- ██╔══╝  ██║  ██║██║  ██║  ╚██╔╝      ╚════██║██║▄▄ ██║██║     
-- ███████╗██████╔╝██████╔╝   ██║       ███████║╚██████╔╝███████╗
-- ╚══════╝╚═════╝ ╚═════╝    ╚═╝       ╚══════╝ ╚══▀▀═╝ ╚══════╝

use plsport_playsport;

/*(1)整理forum*/
CREATE TABLE plsport_playsport._forum engine = myisam
SELECT c.subjectid, c.allianceid, c.alliancename, c.postuser, d.nickname, c.m, c.replycount
FROM (
    SELECT a.subjectid, a.allianceid, b.alliancename, a.postuser, substr(a.posttime,1,7) as m, a.replycount
    FROM plsport_playsport.forum a LEFT JOIN plsport_playsport.alliance b on a.allianceid = b.allianceid
    WHERE substr(posttime,1,7) between '2012-01' AND '2016-12'
    ORDER BY posttime DESC) as c LEFT JOIN plsport_playsport.member d on c.postuser = d.userid;
/*(2)新增第1個月*/
CREATE TABLE plsport_playsport._forum_top25_ranking engine = myisam
SELECT a.m, a.postuser, a.nickname, a.c
FROM (
    SELECT m, postuser, nickname, count(subjectid) as c 
    FROM plsport_playsport._forum
    GROUP BY m, postuser) as a
WHERE m = '2012-01' ORDER BY a.c DESC limit 1,25;
/*(3)插入其它月份*/
INSERT IGNORE INTO _forum_top25_ranking
SELECT a.m, a.postuser, a.nickname, a.c
FROM (
    SELECT m, postuser, nickname, count(subjectid) as c 
    FROM plsport_playsport._forum
    GROUP BY m, postuser) as a
WHERE m = '2014-03' ORDER BY a.c DESC limit 1,25;

/*  最近120天內的貼文次數和影響度*/
CREATE TABLE user_cluster._user_post_AND_influence engine = myisam
SELECT b.postuser as userid, b.post_count, round((b.replied_count/b.post_count),1) as influence
FROM (
    SELECT a.postuser, count(a.postuser) as post_count, sum(a.replycount) as replied_count
    FROM (
        SELECT subjectid, postuser, posttime, replycount, pushcount 
        FROM plsport_playsport.forum
        WHERE posttime between subdate(now(),120) AND now()
        ORDER BY posttime) as a 
    GROUP BY a.postuser) b; 

/*  最近120天內的回文次數*/
CREATE TABLE user_cluster._user_reply engine = myisam
SELECT a.userid, count(a.subjectid) as reply_count
FROM (
    SELECT subjectid, userid, postdate 
    FROM plsport_playsport.forumcontent /*目前就直接捉全部的*/
    WHERE contenttype=1 AND postdate between subdate(now(),120) AND now()) as a
GROUP BY a.userid;


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
        -- CREATE TABLE plsport_playsport._forum_heavy_poster engine = myisam /*排除重覆的人*/
        -- SELECT userid, nickname, count(c) as c 
        -- FROM plsport_playsport._forum_top50_ranking
        -- GROUP BY userid, nickname;

        --  ALTER TABLE plsport_playsport._forum_heavy_poster ADD INDEX (`userid`);
        --  ALTER TABLE plsport_playsport.member ADD INDEX (`userid`);
        --  ALTER TABLE plsport_playsport._forum ADD INDEX (`postuser`);
        --  ALTER TABLE  plsport_playsport.member CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
        --  ALTER TABLE  plsport_playsport._forum CHANGE  `postuser`  `postuser` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
        --  ALTER TABLE  plsport_playsport._forum_heavy_poster CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

        -- /*_forum join _forum_heavy_poster*/
        -- CREATE TABLE plsport_playsport._FROM_heavy_poster_each_month engine = myisam
        -- SELECT b.m, c.id, b.userid, b.nickname, b.c
        -- FROM (
        --  SELECT a.m, a.userid, a.nickname, count(a.subjectid) as c
        --  FROM (
        --      SELECT a.subjectid, a.allianceid, a.alliancename, a.postuser as userid, a.nickname, a.m
        --      FROM plsport_playsport._forum a inner join plsport_playsport._forum_heavy_poster b on a.postuser = b.userid) as a
        --  GROUP BY a.m, a.userid) b LEFT JOIN plsport_playsport.member c on b.userid = c.userid;


        -- UPDATE plsport_playsport._FROM_heavy_poster_each_month SET userid = TRIM(userid);     #刪掉空白字完
        -- UPDATE plsport_playsport._FROM_heavy_poster_each_month SET nickname = TRIM(nickname); #刪掉空白字完
        -- /*清除nickname奇怪的符號*/
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, '.','');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, ',','');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, 'php','');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, 'admin','');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, ';','');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, '%','');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, '/','');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, '\\','_');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, '+','');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, '-','');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, '*','');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, '#','');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, '&','');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, '$','');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, '^','');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, '~','');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, '!','');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, '?','');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, '"','');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, ' ','_');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, '@','at');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, ':','');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, '','_');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, '∼','_');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, 'циндаогрыжа','_');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, '','_');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, '�','_');
        -- update plsport_playsport._FROM_heavy_poster_each_month SET nickname = replace(nickname, '▽','_');

        -- /*輸出給R使用*/
        -- SELECT 'month', 'id', 'userid', 'nickname', 'posts' UNION(
        -- SELECT * 
        -- INTO outfile 'C:/Python27/eddy_python/www_process/top_posters_for_each_month.csv' 
        -- fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
        -- FROM plsport_playsport._FROM_heavy_poster_each_month);

/*-------任務2014/4/14--------*/
# (1)先把cluster的名單匯進mysql
# (2)再run以下產生沒有損壞的userid

# _forum_heavy_poster是前幾個月中各月前50名貼文者, 然後對映出nickname
CREATE TABLE plsport_playsport._who_is_heavy_poster_in_cluster engine = myisam
SELECT a.userid, a.nickname, b.g  #排除掉沒有在分群的重度發文者
FROM plsport_playsport._forum_heavy_poster a inner join user_cluster.cluster_with_real_userid b on a.userid = b.userid;

# popular是被定義的知名度
# 這段要join的_forum為最近n個月 (和前幾個月中各月前50名貼文者是一樣的TABLE)
CREATE TABLE plsport_playsport._forum_heavy_poster_in_cluster engine = myisam
SELECT a.subjectid, a.allianceid, a.alliancename, a.postuser, a.nickname, a.m, a.viewtimes, a.replycount, a.pushcount, 
       ((a.viewtimes*0.02)+ a.replycount+ (a.pushcount*0.3)) as popular, b.g
FROM plsport_playsport._forum a inner join plsport_playsport._who_is_heavy_poster_in_cluster b on a.postuser = b.userid;

CREATE TABLE plsport_playsport._forum_heavy_poster_in_cluster_score engine = myisam
SELECT postuser, nickname, count(subjectid) as total_posts,
                           round(avg(viewtimes),1) as avg_views, round(avg(replycount),1) as avg_reply, 
                           round(avg(pushcount),1) as avg_push, round(avg(popular),1) as avg_popular, g
FROM plsport_playsport._forum_heavy_poster_in_cluster
GROUP BY postuser;

SELECT *
FROM plsport_playsport._forum_heavy_poster_in_cluster_score
ORDER BY avg_popular DESC;


#===========================================================================================
#    只計算出最近7天的儲值總額
#    to SELECT certian peried time
#===========================================================================================

SELECT 'date', 'revenue' UNION(
SELECT a.d, sum(price) as total_redeem
INTO outfile 'C:/Python27/eddy_python/www_process.csv'
FROM (
    SELECT id, userid, date(CREATEon) as d, price 
    FROM www.order_data
    WHERE sellconfirm = 1
    AND CREATEon between subdate(date(now()),7) AND subdate(date(now()),0)) as a/*7 days*/
GROUP BY a.d); 


#===========================================================================================
#    update:2014/3/26
#    調察爺爺泡的茶log
#===========================================================================================
SELECT b.uri_2, b.platform_type, count(b.id) as c
FROM (
    SELECT a.id, a.userid, (case when (a.uri_1='') then 'index' else a.uri_1 end ) as uri_2, a.time, a.platform_type
    FROM (
        SELECT id, userid, uri, substr(uri,2, (locate('.php',uri))-2) as uri_1, time, platform_type 
        FROM actionlog._grANDpa) as a) as b
GROUP BY b.uri_2, b.platform_type;



#===========================================================================================
#    2014/4/1儲值優惠活動
#    update:2014/3/26
#    福利班D2,D3簡訊名單
#    去年 4~10月，儲值金額超過199的名單
#===========================================================================================
use plsport_playsport;

#列出order_data中所有有手機號碼的使用者
CREATE TABLE plsport_playsport._user_with_phone engine = myisam
SELECT a.id, a.userid, a.name, a.phone
FROM (
    SELECT b.id, a.userid, a.name, a.phone
    FROM plsport_playsport.order_data a LEFT JOIN plsport_playsport.member b on a.userid = b.userid
    WHERE a.sellconfirm = 1) as a
WHERE a.phone <> ' '
GROUP BY a.id;

    ALTER TABLE plsport_playsport._user_with_phone ADD INDEX (`id`); 
    ALTER TABLE user_cluster.cluster_with_real_userid ADD INDEX (`id`); 

#和分群配對
CREATE TABLE plsport_playsport._user_with_phone_AND_cluster engine = myisam
SELECT a.id, b.userid, a.name, a.phone, b.g
FROM plsport_playsport._user_with_phone a LEFT JOIN user_cluster.cluster_with_real_userid b on a.id = b.id
WHERE b.g is not null;

#找出D2,D3名單
CREATE TABLE plsport_playsport._user_with_phone_all engine = myisam
SELECT userid, name, phone, count(id) as c # D2, D3名單
FROM plsport_playsport._user_with_phone_AND_cluster
WHERE g in ('D2','D3') AND phone <> ' '
GROUP BY userid, name, phone;

INSERT IGNORE INTO plsport_playsport._user_with_phone_all
SELECT a.userid, a.name, a.phone, count(a.userid) as c # 去年4~10月有儲值過的人
FROM (
    SELECT userid, name, phone 
    FROM plsport_playsport.order_data
    WHERE sellconfirm = 1 AND phone <> ' '
    AND CREATEon between '2013-04-01 00:00:00' AND '2013-10-01 23:59:59') as a
GROUP BY a.userid, a.name, a.phone;

CREATE TABLE plsport_playsport._user_with_phone_all_ok engine = myisam
SELECT userid, name, phone, count(phone) as c
FROM plsport_playsport._user_with_phone_all
GROUP BY userid;

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
CREATE TABLE plsport_playsport._user_with_phone_all_ok_1 engine = myisam
SELECT a.userid, a.name, a.phone, b.status 
FROM plsport_playsport._user_with_phone_all_ok a LEFT JOIN plsport_playsport.0401_text_campaign b on a.phone = b.phone_num;

CREATE TABLE plsport_playsport._who_redeem_in_apr1 engine = myisam
SELECT a.userid, a.name, sum(a.price) as redeem
FROM (
    SELECT userid, CREATEon, name, price
    FROM plsport_playsport.order_data
    WHERE CREATEon between '2014-04-01 00:00:00' AND '2014-04-01 23:59:59'
    AND payway in (1,2,3,4,5,6,9,10) AND sellconfirm = 1) as a
GROUP BY a.userid;

CREATE TABLE plsport_playsport._who_redeem_before_apr1 engine = myisam
SELECT a.userid, a.name, sum(a.price) as redeem
FROM (
    SELECT userid, CREATEon, name, price
    FROM plsport_playsport.order_data
    WHERE CREATEon between '2012-01-01 00:00:00' AND '2014-03-31 23:59:59'
    AND payway in (1,2,3,4,5,6,9,10) AND sellconfirm = 1) as a
GROUP BY a.userid;

CREATE TABLE plsport_playsport._who_redeem_after_apr1 engine = myisam
SELECT a.userid, a.name, sum(a.price) as redeem
FROM (
    SELECT userid, CREATEon, name, price
    FROM plsport_playsport.order_data
    WHERE CREATEon between '2014-04-02 00:00:00' AND '2014-04-30 23:59:59'
    AND payway in (1,2,3,4,5,6,9,10) AND sellconfirm = 1) as a
GROUP BY a.userid;

    ALTER TABLE plsport_playsport._who_redeem_in_apr1 ADD INDEX (`userid`);
    ALTER TABLE plsport_playsport._who_redeem_before_apr1 ADD INDEX (`userid`);
    ALTER TABLE plsport_playsport._who_redeem_after_apr1 ADD INDEX (`userid`);
    ALTER TABLE plsport_playsport._who_redeem_in_apr1 CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
    ALTER TABLE plsport_playsport._who_redeem_before_apr1 CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
    ALTER TABLE plsport_playsport._who_redeem_after_apr1 CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

#收到簡訊的人, 當天第是否為第一次消費
CREATE TABLE plsport_playsport._user_with_phone_all_ok_2 engine = myisam 
SELECT e.userid, e.phone, e.status, e.redeem_before, e.redeem_apr1, f.redeem as redeem_after
FROM (
    SELECT c.userid, c.phone, c.status, c.redeem_before, d.redeem as redeem_apr1
    FROM (
        SELECT a.userid, a.phone, a.status, b.redeem as redeem_before
        FROM plsport_playsport._user_with_phone_all_ok_1 a LEFT JOIN plsport_playsport._who_redeem_before_apr1 b on a.userid = b.userid) as c 
        LEFT JOIN plsport_playsport._who_redeem_in_apr1 d on c.userid = d.userid) as e 
    LEFT JOIN plsport_playsport._who_redeem_after_apr1 as f on e.userid = f.userid;

#所有會員, 當天第是否為第一次消費
CREATE TABLE plsport_playsport._member_redeem_apr1 engine = myisam 
SELECT e.userid, e.nickname, e.redeem_before, e.redeem_apr1, f.redeem as redeem_after
FROM (
    SELECT c.userid, c.nickname, c.redeem_before, d.redeem as redeem_apr1
    FROM (
        SELECT a.userid, a.nickname, b.redeem as redeem_before
        FROM plsport_playsport.member a LEFT JOIN plsport_playsport._who_redeem_before_apr1 b on a.userid = b.userid) as c 
        LEFT JOIN plsport_playsport._who_redeem_in_apr1 d on c.userid = d.userid) as e 
    LEFT JOIN plsport_playsport._who_redeem_after_apr1 as f on e.userid = f.userid
WHERE e.redeem_before is not null 
or e.redeem_apr1 is not null
or f.redeem is not null;

#所有人在4/1前最後一次登入的時間
CREATE TABLE plsport_playsport._last_signin_before_apr1 engine = myisam
SELECT a.userid, date(max(a.signin_time)) as least_sign_in
FROM (
    SELECT userid, signin_time 
    FROM plsport_playsport.member_signin_log_archive
    WHERE signin_time between '2009-01-01 00:00:00' AND '2014-03-31 23:59:59') as a
GROUP BY a.userid
ORDER BY userid;

    ALTER TABLE plsport_playsport._last_signin_before_apr1 CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
    ALTER TABLE plsport_playsport._last_signin_before_apr1 ADD INDEX (`userid`);
    ALTER TABLE plsport_playsport._member_redeem_apr1 ADD INDEX (`userid`);

#完整的名單, 和4/1之前, 4/1當天, 4/1之後的儲值金額列表
CREATE TABLE plsport_playsport._member_redeem_apr2 engine = myisam 
SELECT c.userid, c.nickname, date(d.CREATEon) as CREATEon, c.least_sign_in, c.redeem_before, c.redeem_apr1, c.redeem_after 
FROM (
    SELECT a.userid, a.nickname, b.least_sign_in, a.redeem_before, a.redeem_apr1, a.redeem_after 
    FROM plsport_playsport._member_redeem_apr1 a LEFT JOIN plsport_playsport._last_signin_before_apr1 b on a.userid = b.userid) as c
    LEFT JOIN plsport_playsport.member as d on c.userid = d.userid;

    ALTER TABLE plsport_playsport._member_redeem_apr2 ADD INDEX (`userid`);

#4/1當天有使用儲值優惠的人
CREATE TABLE plsport_playsport._member_redeem_apr3 engine = myisam 
SELECT * FROM plsport_playsport._member_redeem_apr2
WHERE redeem_apr1 is not null
AND redeem_apr1 not in (199,228,699,803); #不含儲值999以下的人

    #who_redeem_before_apr1 4/1之前的儲值
    CREATE TABLE plsport_playsport._who_redeem_before_apr1_nogroup engine = myisam 
    SELECT userid, CREATEon, name, price
    FROM plsport_playsport.order_data
    WHERE CREATEon between '2012-01-01 00:00:00' AND '2014-03-31 23:59:59'
    AND payway in (1,2,3,4,5,6,9,10) AND sellconfirm = 1;
    #who_redeem_after_apr1  4/1之後的儲值
    CREATE TABLE plsport_playsport._who_redeem_after_apr1_nogroup engine = myisam 
    SELECT userid, CREATEon, name, price
    FROM plsport_playsport.order_data
    WHERE CREATEon between '2014-04-02 00:00:00' AND '2014-04-30 23:59:59'
    AND payway in (1,2,3,4,5,6,9,10) AND sellconfirm = 1;

    ALTER TABLE plsport_playsport._who_redeem_before_apr1_nogroup ADD INDEX (`userid`);
    ALTER TABLE plsport_playsport._who_redeem_after_apr1_nogroup ADD INDEX (`userid`);

    #4/1當天有使用儲值優惠的人, 前一次的儲值
    CREATE TABLE plsport_playsport._temp1 engine = myisam 
    SELECT c.userid, max(c.CREATEon) as before_apr1_redeem, c.price
    FROM (
        SELECT a.userid, a.CREATEon, a.price 
        FROM plsport_playsport._who_redeem_before_apr1_nogroup a inner join plsport_playsport._member_redeem_apr3 b on a.userid = b.userid) as c
    GROUP BY c.userid;

    #4/1當天有使用儲值優惠的人, 後一次的儲值
    CREATE TABLE plsport_playsport._temp2 engine = myisam 
    SELECT c.userid, min(c.CREATEon) as after_apr1_redeem, c.price
    FROM (
        SELECT a.userid, a.CREATEon, a.price 
        FROM plsport_playsport._who_redeem_after_apr1_nogroup a inner join plsport_playsport._member_redeem_apr3 b on a.userid = b.userid) as c
    GROUP BY c.userid;

    ALTER TABLE plsport_playsport._temp1 ADD INDEX (`userid`);
    ALTER TABLE plsport_playsport._temp2 ADD INDEX (`userid`);

CREATE TABLE plsport_playsport._member_redeem_apr4 engine = myisam 
SELECT c.userid, c.nickname, c.CREATEon, c.least_sign_in, c.redeem_before, c.redeem_apr1, c.redeem_after, 
       date(c.before_apr1_redeem) as d_1, c._apr1_before, date(d.after_apr1_redeem) as d_2 ,d.price as _apr1_after
FROM (
    SELECT a.userid, a.nickname, a.CREATEon, a.least_sign_in, a.redeem_before, a.redeem_apr1, a.redeem_after, b.before_apr1_redeem ,b.price as _apr1_before 
    FROM plsport_playsport._member_redeem_apr3 a LEFT JOIN plsport_playsport._temp1 b on a.userid = b.userid) as c 
    LEFT JOIN plsport_playsport._temp2 as d on c.userid = d.userid;

    drop TABLE plsport_playsport._temp1;
    drop TABLE plsport_playsport._temp2;


#=============================================
#    福利班追加任務 2014/4/11    
#=============================================

# 誰在福利班的條件下有儲值過噱幣?
CREATE TABLE plsport_playsport._who_redeem_last_year engine = myisam
SELECT userid, name, count(phone) as c, (case when (userid is not null) then 'yes' end) as whoredeemlastyear
FROM (
    SELECT userid, name, phone 
    FROM plsport_playsport.order_data
    WHERE sellconfirm = 1 AND phone <> ' '
    AND CREATEon between '2013-04-01 00:00:00' AND '2013-10-01 23:59:59') as a
GROUP BY userid, name;

# 最後一次登入的記錄
CREATE TABLE plsport_playsport._who_last_sign_in_before_Apr1 engine = myisam
SELECT a.userid, a.last_sign_in, substr(a.last_sign_in,1,7) as m
FROM (
    SELECT userid, max(signin_time) as last_sign_in 
    FROM plsport_playsport.member_signin_log_archive
    WHERE date(signin_time) between '2013-01-01' AND '2014-03-31'
    GROUP BY userid
    ORDER BY signin_time DESC) as a;

    ALTER TABLE plsport_playsport._who_redeem_last_year         CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
    ALTER TABLE plsport_playsport._who_last_sign_in_before_Apr1 CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
    ALTER TABLE plsport_playsport._who_redeem_last_year         ADD INDEX (`userid`); 
    ALTER TABLE plsport_playsport._who_last_sign_in_before_Apr1 ADD INDEX (`userid`); 

CREATE TABLE plsport_playsport._who_redeem_last_year_1 engine = myisam
SELECT a.userid, a.name, a.c, a.whoredeemlastyear, b.last_sign_in, substr(b.last_sign_in,1,7) as m
FROM plsport_playsport._who_redeem_last_year a LEFT JOIN plsport_playsport._who_last_sign_in_before_apr1 b on a.userid = b.userid;

CREATE TABLE plsport_playsport._who_redeem_last_year_2 engine = myisam
SELECT userid, name, c, whoredeemlastyear, (case when (m is null) then '2013-06' else m end) as m
FROM plsport_playsport._who_redeem_last_year_1;

CREATE TABLE plsport_playsport._who_redeem_at_apr1 engine = myisam
SELECT a.userid, count(a.price) as redeem_count, sum(a.price) as redeem_total
FROM (
    SELECT userid, price 
    FROM plsport_playsport.order_data
    WHERE sellconfirm = 1
    AND CREATEon between '2014-04-01 00:00:00' AND '2014-04-01 23:59:59') as a
GROUP BY a.userid;

    ALTER TABLE plsport_playsport._who_redeem_at_apr1 CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
    ALTER TABLE plsport_playsport._who_redeem_at_apr1 ADD INDEX (`userid`); 

CREATE TABLE plsport_playsport._who_redeem_last_year_3 engine = myisam
SELECT a.userid, a.name, a.c, a.whoredeemlastyear, a.m, b.redeem_count, b.redeem_total
FROM plsport_playsport._who_redeem_last_year_2 a LEFT JOIN plsport_playsport._who_redeem_at_apr1 b on a.userid = b.userid;


SELECT m, count(userid) as user_count
FROM plsport_playsport._who_redeem_last_year_3
WHERE redeem_count is not null
GROUP BY m;

SELECT m, sum(redeem_count) as redeem_count, sum(redeem_total) as redeem_total
FROM plsport_playsport._who_redeem_last_year_3
WHERE redeem_count is not null
GROUP BY m;


#=============================================
#   柔雅追加任務 2014/7/8                     
#=============================================

CREATE TABLE plsport_playsport._who_redeem_in_apr_1 engine = myisam  #誰在4/1當日儲值
SELECT userid, CREATEon, ordernumber, sum(price) as redeem, payway, CREATE_FROM
FROM plsport_playsport.order_data
WHERE sellconfirm = 1 
AND CREATE_FROM = 8
AND CREATEon between '2014-04-01 00:00:00' AND '2014-04-01 23:59:59'
GROUP BY userid;

        CREATE TABLE plsport_playsport._who_redeem_in_apr_1_max engine = myisam  #誰在4/1當日儲值(最大金額)
        SELECT userid, CREATEon, ordernumber, max(price) as redeem_max, payway, CREATE_FROM
        FROM plsport_playsport.order_data
        WHERE sellconfirm = 1 
        AND CREATE_FROM = 8
        AND CREATEon between '2014-04-01 00:00:00' AND '2014-04-01 23:59:59'
        GROUP BY userid;

CREATE TABLE plsport_playsport._who_redeem_before_apr_1 engine = myisam  #誰在4/1之前儲值
SELECT userid, sum(price) as redeem_before_apr_1  
FROM plsport_playsport.order_data
WHERE sellconfirm = 1
AND CREATEon between '2010-01-01 00:00:00' AND '2014-03-31 23:59:59'
GROUP BY userid;

        CREATE TABLE plsport_playsport._who_redeem_before_apr_1_max engine = myisam  #誰在4/1之前儲值(最大金額)
        SELECT userid, max(price) as redeem_before_apr_1_max  
        FROM plsport_playsport.order_data
        WHERE sellconfirm = 1
        AND CREATEon between '2010-01-01 00:00:00' AND '2014-03-31 23:59:59'
        GROUP BY userid;

CREATE TABLE plsport_playsport._who_redeem_after_apr_1 engine = myisam  #誰在4/1之後當日儲值
SELECT userid, sum(price) as redeem_after_apr_1  
FROM plsport_playsport.order_data
WHERE sellconfirm = 1
AND CREATEon between '2014-04-02 00:00:00' AND '2014-06-30 23:59:59'
GROUP BY userid;

        CREATE TABLE plsport_playsport._who_redeem_after_apr_1_max engine = myisam  #誰在4/1之後當日儲值(最大金額)
        SELECT userid, max(price) as redeem_after_apr_1_max 
        FROM plsport_playsport.order_data
        WHERE sellconfirm = 1
        AND CREATEon between '2014-04-02 00:00:00' AND '2014-06-30 23:59:59'
        GROUP BY userid;

ALTER TABLE plsport_playsport._who_redeem_in_apr_1 ADD INDEX (`userid`);
ALTER TABLE plsport_playsport._who_redeem_in_apr_1_max ADD INDEX (`userid`); 
ALTER TABLE plsport_playsport._who_redeem_before_apr_1 ADD INDEX (`userid`); 
ALTER TABLE plsport_playsport._who_redeem_before_apr_1_max ADD INDEX (`userid`); 
ALTER TABLE plsport_playsport._who_redeem_after_apr_1 ADD INDEX (`userid`); 
ALTER TABLE plsport_playsport._who_redeem_after_apr_1_max ADD INDEX (`userid`); 


CREATE TABLE plsport_playsport._main_redeem_1 engine = myisam
SELECT c.userid, c.CREATEon, c.ordernumber, c.redeem_before_apr_1_max, c.redeem_max, d.redeem_after_apr_1_max
FROM (
    SELECT a.userid, a.CREATEon, a.ordernumber, b.redeem_before_apr_1_max, a.redeem_max
    FROM plsport_playsport._who_redeem_in_apr_1_max a LEFT JOIN plsport_playsport._who_redeem_before_apr_1_max b on a.userid = b.userid) as c
    LEFT JOIN plsport_playsport._who_redeem_after_apr_1_max d on c.userid = d.userid;

CREATE TABLE plsport_playsport._main_redeem_2 engine = myisam
SELECT c.userid, c.CREATEon, c.ordernumber, c.redeem_before_apr_1, c.redeem, d.redeem_after_apr_1
FROM (
    SELECT a.userid, a.CREATEon, a.ordernumber, b.redeem_before_apr_1, a.redeem
    FROM plsport_playsport._who_redeem_in_apr_1 a LEFT JOIN plsport_playsport._who_redeem_before_apr_1 b on a.userid = b.userid) as c
    LEFT JOIN plsport_playsport._who_redeem_after_apr_1 d on c.userid = d.userid;

CREATE TABLE plsport_playsport._main_redeem_3 engine = myisam
SELECT a.userid, a.CREATEon, a.ordernumber, a.redeem_before_apr_1_max, a.redeem_max, a.redeem_after_apr_1_max, 
       b.redeem_before_apr_1, b.redeem, b.redeem_after_apr_1
FROM plsport_playsport._main_redeem_1 a LEFT JOIN plsport_playsport._main_redeem_2 b on a.userid = b.userid;


CREATE TABLE plsport_playsport._who_redeem_when_next_time engine = myisam  #誰在4/1之後當日儲值
SELECT userid, min(CREATEon) as next_time, price as next_redeem
FROM plsport_playsport.order_data
WHERE sellconfirm = 1
AND CREATEon between '2014-04-02 00:00:00' AND '2014-06-30 23:59:59'
GROUP BY userid;

CREATE TABLE plsport_playsport._main_redeem_4 engine = myisam
SELECT a.userid, a.CREATEon, a.ordernumber, a.redeem_before_apr_1_max, a.redeem_max, a.redeem_after_apr_1_max, 
       a.redeem_before_apr_1, a.redeem, a.redeem_after_apr_1, b.next_time, b.next_redeem
FROM plsport_playsport._main_redeem_3 a LEFT JOIN plsport_playsport._who_redeem_when_next_time b on a.userid = b.userid;

#===========================================================================================
# 麻煩再幫我們分析: 2014-07-14
# 使用者活動前後的arpu，查看該使用者在活動結束後的arpu是否有增高。
# 1. 有用到優惠的人
# 2. 沒有用到優惠的人
#===========================================================================================

CREATE TABLE plsport_playsport._who_redeem_in_apr_1_max engine = myisam  #誰在4/1當日儲值(最大金額)
SELECT userid, CREATEon, ordernumber, max(price) as redeem_max, payway, CREATE_FROM
FROM plsport_playsport.order_data
WHERE sellconfirm = 1 
AND CREATE_FROM = 8
AND CREATEon between '2014-04-01 00:00:00' AND '2014-04-01 23:59:59'
GROUP BY userid;

CREATE TABLE plsport_playsport._who_redeem_in_apr_1_max_14_days engine = myisam  #誰在4/1當日儲值(最大金額)
SELECT userid, CREATEon, ordernumber, max(price) as redeem_max, payway, CREATE_FROM
FROM plsport_playsport.order_data
WHERE sellconfirm = 1 
AND CREATEon between '2014-03-25 00:00:00' AND '2014-04-05 23:59:59'
GROUP BY userid;

CREATE TABLE plsport_playsport._who_not_redeem_in_apr_1_max engine = myisam
SELECT a.userid, a.CREATEon, a.ordernumber, a.redeem_max, a.payway, a.CREATE_FROM 
FROM plsport_playsport._who_redeem_in_apr_1_max_14_days a LEFT JOIN plsport_playsport._who_redeem_in_apr_1_max b on a.userid = b.userid
WHERE b.userid is null;


CREATE TABLE plsport_playsport._list_A engine = myisam
SELECT userid, (case when (userid is not null) then 'A' end) as g 
FROM plsport_playsport._who_redeem_in_apr_1_max;

CREATE TABLE plsport_playsport._list_B engine = myisam
SELECT userid, (case when (userid is not null) then 'B' end) as g
FROM plsport_playsport._who_not_redeem_in_apr_1_max;


CREATE TABLE plsport_playsport._list engine = myisam SELECT * FROM plsport_playsport._list_A;
INSERT IGNORE INTO plsport_playsport._list SELECT * FROM plsport_playsport._list_B;


CREATE TABLE plsport_playsport._redeem_next_3_months engine = myisam  
SELECT userid, substr(CREATEon,1,7) as m, sum(price) as redeem, count(price) as redeem_count
FROM plsport_playsport.order_data
WHERE sellconfirm = 1 
AND CREATEon between '2014-04-06 00:00:00' AND '2014-07-05 23:59:59'
GROUP BY userid, m;

SELECT c.g, c.m, sum(c.redeem) as redeem, count(c.userid) as users
FROM (
    SELECT a.userid, a.m, a.redeem, a.redeem_count, b.g 
    FROM plsport_playsport._redeem_next_3_months a LEFT JOIN plsport_playsport._list b on a.userid = b.userid
    WHERE b.g is not null AND a.redeem < 17000) as c 
GROUP BY c.g, c.m;


SELECT d.g, sum(d.redeem) as redeem , count(d.userid) as users
FROM (
    SELECT c.userid, sum(c.redeem) as redeem, c.g
    FROM (
        SELECT a.userid, a.m, a.redeem, a.redeem_count, b.g 
        FROM plsport_playsport._redeem_next_3_months a LEFT JOIN plsport_playsport._list b on a.userid = b.userid
        WHERE b.g is not null AND a.redeem < 17000) as c
    GROUP BY c.userid) as d
GROUP BY d.g;


#===========================================================================================
#    update:2014/4/3
#    分析文觀看比例
#    請調查 2014/1/9, 3/6有觀看最讚分析文的會員比例
#    舉例來說：3/6共有 2000人觀看當日發表的最讚分析文，佔當日有看討論區會員的 20%
#===========================================================================================
use actionlog;

CREATE TABLE actionlog._forum_log_JAN engine = myisam
SELECT id, userid, uri, time
FROM actionlog.action_201401
WHERE time between '2014-01-05 00:00:00' AND '2014-01-11 23:59:59'
AND userid <> ''
AND uri LIKE '%forum%';

CREATE TABLE actionlog._forum_log_MAR engine = myisam
SELECT id, userid, uri, time
FROM actionlog.action_201403
WHERE time between '2014-03-02 00:00:00' AND '2014-03-08 23:59:59'
AND userid <> ''
AND uri LIKE '%forum%';

    INSERT IGNORE INTO actionlog._forum_log_JAN SELECT * FROM actionlog._forum_log_MAR;
    rename TABLE actionlog._forum_log_JAN to actionlog._forum_log;
    drop TABLE actionlog._forum_log_MAR;

# 所有看討論區的完整log
CREATE TABLE actionlog._forum_log_allviwers engine = myisam
SELECT id, userid, uri, substr(uri,2, (locate('.php',uri))-2) as uri_1, time  
FROM actionlog._forum_log;

# 所有看文章內文的完整log並捉出subjectid
CREATE TABLE actionlog._forumdetail_log_allviwers engine = myisam
SELECT b.id, b.userid, b.uri, b.uri1, b.e, b.time
FROM (
    SELECT a.id, a.userid, a.uri, a.uri1, locate('&', a.uri1)-1 as e, a.time #&之前的字串位置
    FROM (
        SELECT id, userid, uri, substr(uri,(locate('subjectid=',uri) +10)) as uri1,time #捉出subjectid的內容
        FROM actionlog._forum_log
        WHERE uri LIKE '%subjectid=%') as a) as b 
WHERE b.e in (-1, 15);

CREATE TABLE actionlog._forumdetail_log_allviwers1 engine = myisam
SELECT id, userid, substr(uri,2, (locate('.php',uri))-2) as s_uri, substr(uri1,1,15) as subjectid, time 
FROM actionlog._forumdetail_log_allviwers;

# 處理分析王的文章表格, 要指定好區間 
CREATE TABLE plsport_playsport._analysis_king engine = myisam 
SELECT id, userid, allianceid, subjectid, reply_count, push_count, d, gamedate,
       (case when (subjectid is not null) then 'ana_post' end) as isana
FROM (
    SELECT id, userid, allianceid, subjectid, reply_count, push_count, date(got_time) as d, gamedate
    FROM plsport_playsport.analysis_king) as a 
WHERE a.d between '2014-01-05' AND '2014-03-08';

    ALTER TABLE plsport_playsport._analysis_king      ADD INDEX (`subjectid`); 
    ALTER TABLE actionlog._forumdetail_log_allviwers1 ADD INDEX (`subjectid`); 
    ALTER TABLE actionlog._forumdetail_log_allviwers1 CHANGE  `subjectid`  `subjectid` VARCHAR( 15 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT  '';
    ALTER TABLE plsport_playsport._analysis_king      CHANGE  `subjectid`  `subjectid` VARCHAR( 30 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

CREATE TABLE actionlog._forumdetail_log_allviwers1_with_ana engine = myisam
SELECT a.id, a.userid, a.s_uri, a.subjectid, a.time, b.isana
FROM actionlog._forumdetail_log_allviwers1 a LEFT JOIN plsport_playsport._analysis_king b on a.subjectid = b.subjectid;

CREATE TABLE actionlog._forumdetail_log_allviwers1_with_ana1 engine = myisam
SELECT a.userid, a.s_uri, a.subjectid, a.d, a.isana, count(subjectid) as c
FROM (
    SELECT userid, s_uri, subjectid, date(time) as d, isana
    FROM actionlog._forumdetail_log_allviwers1_with_ana) as a
GROUP BY a.userid, a.s_uri, a.subjectid, a.d;

/*-----------------------------------------------------
    查詢: 每天有看討論區的人數
-----------------------------------------------------*/
SELECT a.d, count(a.userid) as viwer_count
FROM (
    SELECT d, userid, count(subjectid) as c 
    FROM actionlog._forumdetail_log_allviwers1_with_ana1
    GROUP BY d, userid) as a
GROUP BY a.d;
/*-----------------------------------------------------
    查詢: 每天有看分析王文章的人數
-----------------------------------------------------*/
SELECT a.d, count(a.userid) as viwer_count
FROM (
    SELECT d, userid, count(subjectid) as c 
    FROM actionlog._forumdetail_log_allviwers1_with_ana1
    WHERE isana is not null # 該文被評選為分析王
    GROUP BY d, userid) as a
GROUP BY a.d;
/*-----------------------------------------------------
    追加任務:2014/4/10 當天有多少人登入
-----------------------------------------------------*/
CREATE TABLE actionlog._log_JAN engine = myisam
SELECT id, userid, uri, time
FROM actionlog.action_201401
WHERE time between '2014-01-05 00:00:00' AND '2014-01-11 23:59:59'
AND userid <> '';

CREATE TABLE actionlog._log_MAR engine = myisam
SELECT id, userid, uri, time
FROM actionlog.action_201403
WHERE time between '2014-03-02 00:00:00' AND '2014-03-08 23:59:59'
AND userid <> '';

    INSERT IGNORE INTO actionlog._log_JAN SELECT * FROM actionlog._log_MAR;
    rename TABLE actionlog._log_JAN to actionlog._log;
    drop TABLE actionlog._log_MAR;

CREATE TABLE actionlog._log_1 engine = myisam
SELECT id, userid, uri, date(time) as d
FROM actionlog._log;

CREATE TABLE actionlog._log_2 engine = myisam
SELECT d, userid, count(id) as c 
FROM actionlog._log_1
GROUP BY d, userid;

SELECT d, count(userid) as c 
FROM actionlog._log_2
GROUP BY d;


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
CREATE TABLE actionlog._forum_log_JAN engine = myisam # 1月
SELECT id, userid, uri, time 
FROM actionlog.action_201401
WHERE userid <> '' AND uri LIKE '%forumdetail%';

CREATE TABLE actionlog._forum_log_FEB engine = myisam # 2月
SELECT id, userid, uri, time 
FROM actionlog.action_201402
WHERE userid <> '' AND uri LIKE '%forumdetail%';

CREATE TABLE actionlog._forum_log_MAR engine = myisam # 3月
SELECT id, userid, uri, time 
FROM actionlog.action_201403
WHERE userid <> '' AND uri LIKE '%forumdetail%';

CREATE TABLE actionlog._forum_log_APR engine = myisam # 4月
SELECT id, userid, uri, time 
FROM actionlog.action_201404
WHERE userid <> '' AND uri LIKE '%forumdetail%';

    INSERT IGNORE INTO actionlog._forum_log_JAN SELECT * FROM actionlog._forum_log_FEB;
    INSERT IGNORE INTO actionlog._forum_log_JAN SELECT * FROM actionlog._forum_log_MAR;
    INSERT IGNORE INTO actionlog._forum_log_JAN SELECT * FROM actionlog._forum_log_APR;
    drop TABLE actionlog._forum_log_FEB;
    drop TABLE actionlog._forum_log_MAR;
    drop TABLE actionlog._forum_log_APR;
    rename TABLE actionlog._forum_log_JAN to actionlog._forum_log; # 合併成一個

CREATE TABLE actionlog._forum_log_1 engine = myisam # 開始分析subjectid
SELECT id, userid, uri, substr(uri,(locate('subjectid=',uri) +10)) as uri1,time
FROM actionlog._forum_log;

CREATE TABLE actionlog._forum_log_2 engine = myisam # 取出subjectid, 並移掉奇怪的subjectid
SELECT a.id, a.userid, a.uri, a.uri1, a.e, a.time
FROM (
    SELECT id, userid, uri, uri1, locate('&', uri1)-1 as e, time 
    FROM actionlog._forum_log_1) as a
WHERE a.e in (-1, 15);

CREATE TABLE actionlog._forum_log_3 engine = myisam # 整理subjectid
SELECT id, userid, substr(uri1,1,15) as subjectid, date(time) as d
FROM actionlog._forum_log_2;

/*匯入analysis_king*/
/*找出FEB到APR之間的最讚分析文*/
CREATE TABLE plsport_playsport._analysis_king_feb_apr engine = myisam 
SELECT userid, subjectid, got_time, gamedate, 
       (case when (subjectid is not null) then 'y' end) as isanalysispost
FROM plsport_playsport.analysis_king
WHERE got_time between '2014-02-01 00:00:00' AND '2014-04-30 23:59:59'
ORDER BY got_time DESC;

    ALTER TABLE plsport_playsport._analysis_king_feb_apr ADD INDEX (`subjectid`); 
    ALTER TABLE actionlog._forum_log_3 ADD INDEX (`subjectid`); 
    ALTER TABLE plsport_playsport._analysis_king_feb_apr CHANGE  `subjectid`  `subjectid` VARCHAR( 30 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
    ALTER TABLE actionlog._forum_log_3 CHANGE  `subjectid`  `subjectid` VARCHAR( 15 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT  '';

CREATE TABLE actionlog._forum_log_4_with_post engine = myisam # join
SELECT a.id, a.userid, a.subjectid, a.d, b.isanalysispost
FROM actionlog._forum_log_3 a LEFT JOIN plsport_playsport._analysis_king_feb_apr b on a.subjectid = b.subjectid;

CREATE TABLE actionlog._forum_log_5_who_read_analysis engine = myisam # 留下有看過分析文的log
SELECT id, userid, subjectid, d, substr(d,1,7) as m, isanalysispost 
FROM actionlog._forum_log_4_with_post
WHERE isanalysispost is not null;

CREATE TABLE actionlog._forum_log_5_who_read_analysis_1 engine = myisam # 排除閱讀重覆的subjectid
SELECT userid, subjectid, count(id) as c 
FROM actionlog._forum_log_5_who_read_analysis
GROUP BY userid, subjectid;

CREATE TABLE actionlog._forum_log_6 engine = myisam # 實際上每個user看到多少文析文
SELECT a.userid, a.c
FROM (
    SELECT userid, count(subjectid) as c 
    FROM actionlog._forum_log_5_who_read_analysis_1
    GROUP BY userid) as a 
ORDER BY a.c DESC;

    ALTER TABLE actionlog._forum_log_6 ADD INDEX (`userid`); 
    ALTER TABLE actionlog._forum_log_6 CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

CREATE TABLE actionlog._forum_log_7_with_nickname engine = myisam
SELECT a.userid, b.nickname, date(b.CREATEon) as d ,a.c
FROM actionlog._forum_log_6 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

#加入2月~4月的儲值金額
CREATE TABLE plsport_playsport._order_data_feb_apr engine = myisam
SELECT a.userid, sum(a.price) as redeem_total
FROM (
    SELECT userid, price, substr(CREATEon,1,7) as m
    FROM plsport_playsport.order_data
    WHERE sellconfirm = 1 AND payway in (1,2,3,4,5,6,9,10)
    AND CREATEon between '2014-02-01 00:00:00' AND '2014-04-30 23:59:59') as a 
GROUP BY a.userid;

#加入全歷史的儲值金額
CREATE TABLE plsport_playsport._order_data_all_time engine = myisam
SELECT a.userid, sum(a.price) as redeem_total
FROM (
    SELECT userid, price, substr(CREATEon,1,7) as m
    FROM plsport_playsport.order_data
    WHERE sellconfirm = 1 AND payway in (1,2,3,4,5,6,9,10)) as a 
GROUP BY a.userid;

    ALTER TABLE plsport_playsport._order_data_feb_apr  ADD INDEX (userid); 
    ALTER TABLE plsport_playsport._order_data_all_time ADD INDEX (userid); 
    ALTER TABLE actionlog._forum_log_7_with_nickname   ADD INDEX (userid); 

CREATE TABLE actionlog._forum_log_8 engine = myisam
SELECT c.userid, c.nickname, c.d, c.c, c.redeem_total, d.redeem_total as redeem_total_all_time
FROM (
    SELECT a.userid, a.nickname, a.d, a.c, b.redeem_total
    FROM actionlog._forum_log_7_with_nickname a LEFT JOIN plsport_playsport._order_data_feb_apr b 
    on a.userid = b.userid) c LEFT JOIN plsport_playsport._order_data_all_time d on c.userid = d.userid;

UPDATE actionlog._forum_log_8 SET nickname = TRIM(nickname);            #刪掉空白字完
update actionlog._forum_log_8 SET nickname = replace(nickname, '.',''); #清除nickname奇怪的符號...
update actionlog._forum_log_8 SET nickname = replace(nickname, ',','');
update actionlog._forum_log_8 SET nickname = replace(nickname, ';','');
update actionlog._forum_log_8 SET nickname = replace(nickname, '%','');
update actionlog._forum_log_8 SET nickname = replace(nickname, '/','');
update actionlog._forum_log_8 SET nickname = replace(nickname, '\\','_');
update actionlog._forum_log_8 SET nickname = replace(nickname, '*','');
update actionlog._forum_log_8 SET nickname = replace(nickname, '#','');
update actionlog._forum_log_8 SET nickname = replace(nickname, '&','');
update actionlog._forum_log_8 SET nickname = replace(nickname, '$','');

    # 輸出csv到桌面
    SELECT 'userid', 'nickname', 'CREATEon', 'read_count', 'redeem', 'redeem_all_time' UNION (
    SELECT * 
    INTO outfile 'C:/Users/1-7_ASUS/Desktop/who_love_to_read_analysis_post.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM actionlog._forum_log_8);


/*...............................................*/
/*   PART 2                                      */
/*...............................................*/

use plsport_playsport;
#誰是優質分析王
CREATE TABLE plsport_playsport._analysis_king_whoisbest engine = myisam
SELECT b.userid, b.m, b.subjectid_count, (case when (b.userid is not null) then 'y' end) as best_analysis_king
FROM (
    SELECT a.userid, a.m, count(a.subjectid) as subjectid_count
    FROM (
        SELECT userid, subjectid, substr(gamedate,1,6) as m 
        FROM plsport_playsport.analysis_king
        WHERE substr(gamedate,1,6) between '201304' AND '201403') as a
    GROUP BY a.userid, a.m
    ORDER BY a.m) as b 
WHERE b.subjectid_count >11
ORDER BY b.m, b.subjectid_count DESC;

CREATE TABLE plsport_playsport._analysis_king_13apr_14mar engine = myisam #201304~201403
SELECT userid, allianceid, subjectid, reply_count, push_count, gamedate, substr(gamedate,1,6) as m
FROM plsport_playsport.analysis_king
WHERE substr(gamedate,1,6) between '201304' AND '201403';

ALTER TABLE  `_analysis_king_whoisbest`   CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  `_analysis_king_13apr_14mar` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

CREATE TABLE plsport_playsport._analysis_king_whoisbest_post_detail engine = myisam
SELECT a.userid, a.allianceid, a.subjectid, a.reply_count, a.push_count, a.gamedate, a.m, b.best_analysis_king 
FROM plsport_playsport._analysis_king_13apr_14mar a inner join plsport_playsport._analysis_king_whoisbest b on a.userid = b.userid
ORDER BY a.userid, a.m;

CREATE TABLE plsport_playsport._analysis_king_whoisbest_post_detail_with_name engine = myisam
SELECT a.userid, b.nickname, a.allianceid, a.subjectid, a.reply_count, a.push_count, a.gamedate, a.m, a.best_analysis_king
FROM plsport_playsport._analysis_king_whoisbest_post_detail a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

SELECT userid,  nickname, count(subjectid) as c, round(avg(reply_count),1) as avg_reply, round(avg(push_count),1) as avg_push
FROM plsport_playsport._analysis_king_whoisbest_post_detail_with_name
GROUP BY userid;



#===========================================================================================
#    update:2014/4/3
#    即時比分加上殺手推薦 - 研究未登入使用者路徑
#    1. 每天有多少未登入使用者是直接進到即時比分頁
#    2. 呈上題，多少未登入使用者除了即時比分外，沒有使用其他功能
#===========================================================================================

CREATE TABLE actionlog._not_login_log engine = myisam
SELECT id, userid, uri, time, cookie_stamp 
FROM actionlog.action_201403
WHERE time between '2014-03-23 00:00:00' AND '2014-03-31 23:59:59'
AND userid =''
ORDER BY cookie_stamp DESC, time DESC;

CREATE TABLE actionlog._not_login_log_edited engine = myisam
SELECT id, userid, substr(uri,2, (locate('.php',uri))-2) as uri_1, time, cookie_stamp 
FROM actionlog._not_login_log;

CREATE TABLE actionlog._not_login_log_edited_1 engine = myisam
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
CREATE TABLE actionlog._not_login_log_edited_2 engine = myisam
SELECT id, date(time) as d, cookie_stamp, uri_2 
FROM actionlog._not_login_log_edited_1
WHERE time between '2014-03-23 00:00:00' AND '2014-03-26 23:59:59';

CREATE TABLE actionlog._not_login_log_edited_2_1 engine = myisam
SELECT d, cookie_stamp, uri_2, count(id) as c 
FROM actionlog._not_login_log_edited_2
WHERE cookie_stamp <> ''
GROUP BY d, cookie_stamp, uri_2;

    # 查詢當天有多少cookie是未登入的
    SELECT a.d, count(a.cookie_stamp) as e
    FROM (
        SELECT d, cookie_stamp, count(uri_2) as c 
        FROM actionlog._not_login_log_edited_2_1
        GROUP BY d, cookie_stamp) as a
    GROUP BY a.d;

# 誰造訪過livescore
CREATE TABLE actionlog._who_use_livescore engine = myisam
SELECT cookie_stamp, count(id) as c
FROM actionlog._not_login_log_edited_2
WHERE uri_2 LIKE '%livescore%'
GROUP BY cookie_stamp;

    ALTER TABLE actionlog._who_use_livescore ADD INDEX (`cookie_stamp`); 
    ALTER TABLE actionlog._not_login_log_edited_2 ADD INDEX (`cookie_stamp`); 

# [未登入]先找出曾經用過livescore的log
CREATE TABLE actionlog._not_login_log_edited_3 engine = myisam
SELECT a.id, a.d, a.cookie_stamp, a.uri_2 
FROM actionlog._not_login_log_edited_2 a inner join actionlog._who_use_livescore b on a.cookie_stamp = b.cookie_stamp;

    SELECT count(a.cookie_stamp) as c
    FROM (
        SELECT cookie_stamp, count(id) 
        FROM actionlog._not_login_log_edited_3
        GROUP BY cookie_stamp) as a;

/*輸出給excel使用*/
SELECT 'cookie', 'd', 'uri', 'c' UNION(
SELECT cookie_stamp, d,  uri_2, count(id) as c 
INTO outfile 'C:/Users/1-7_ASUS/Desktop/0323-0326_log.csv' 
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM actionlog._not_login_log_edited_3
GROUP BY cookie_stamp, d, uri_2);



#===========================================================================================
#    2014/4/29
#    購牌專區的問券
#===========================================================================================

CREATE TABLE plsport_playsport._questionnaire engine = myisam
SELECT userid, write_time, spend_minute, sort, fixinfo, recommend 
FROM plsport_playsport.questionnaire_buypredict_answer
WHERE spend_minute > 0.3
AND fixinfo <> "1,2,3,4,5,6,7";

CREATE TABLE plsport_playsport._who_paid_before engine = myisam
SELECT buyerid, sum(buy_price) as total_revenue 
FROM plsport_playsport.predict_buyer
GROUP BY buyerid;

    ALTER TABLE plsport_playsport._who_paid_before ADD INDEX (`buyerid`); 
    ALTER TABLE plsport_playsport._questionnaire ADD INDEX (`userid`); 

CREATE TABLE plsport_playsport._questionnaire_with_revenue engine = myisam
SELECT a.userid, a.write_time, a.spend_minute, a.sort, a.fixinfo, a.recommend, b.total_revenue 
FROM plsport_playsport._questionnaire a LEFT JOIN plsport_playsport._who_paid_before b on b.buyerid = a.userid;

    ALTER TABLE plsport_playsport._questionnaire_with_revenue ADD INDEX (`userid`); 

CREATE TABLE plsport_playsport._questionnaire_with_revenue_AND_nickname engine = myisam
SELECT a.userid, b.nickname, a.write_time, a.spend_minute, a.sort, a.fixinfo, a.recommend, a.total_revenue
FROM plsport_playsport._questionnaire_with_revenue a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

update plsport_playsport._questionnaire_with_revenue SET recommend = TRIM(recommend);  #刪掉空白字完
update plsport_playsport._questionnaire_with_revenue SET recommend = replace(recommend, '.',''); 
update plsport_playsport._questionnaire_with_revenue SET recommend = replace(recommend, ';','');
update plsport_playsport._questionnaire_with_revenue SET recommend = replace(recommend, '/','');
update plsport_playsport._questionnaire_with_revenue SET recommend = replace(recommend, '\\','_');
update plsport_playsport._questionnaire_with_revenue SET recommend = replace(recommend, '"','');
update plsport_playsport._questionnaire_with_revenue SET recommend = replace(recommend, '&','');
update plsport_playsport._questionnaire_with_revenue SET recommend = replace(recommend, '#','');
update plsport_playsport._questionnaire_with_revenue SET recommend = replace(recommend, ' ','');
update plsport_playsport._questionnaire_with_revenue SET recommend = replace(recommend, '*','');
update plsport_playsport._questionnaire_with_revenue SET recommend = replace(recommend, '\r','_');
update plsport_playsport._questionnaire_with_revenue SET recommend = replace(recommend, '\n','_');

ALTER TABLE  `_questionnaire_with_revenue_AND_nickname` CHANGE  `nickname`  `nickname` CHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ;

SELECT 'userid', 'nickname','date', 'Q1', 'Q2', 'a1', 'a2','a3','a4','a5','a6','a7','total_revenue','feedback' UNION (
SELECT userid, nickname, date(write_time) as d, sort, fixinfo,
       (case when (fixinfo LIKE '%1%') then 1 else 0 end) as a1,
       (case when (fixinfo LIKE '%2%') then 1 else 0 end) as a2,
       (case when (fixinfo LIKE '%3%') then 1 else 0 end) as a3,
       (case when (fixinfo LIKE '%4%') then 1 else 0 end) as a4,
       (case when (fixinfo LIKE '%5%') then 1 else 0 end) as a5,
       (case when (fixinfo LIKE '%6%') then 1 else 0 end) as a6,
       (case when (fixinfo LIKE '%7%') then 1 else 0 end) as a7,
        total_revenue, recommend
INTO outfile 'C:/Users/1-7_ASUS/Desktop/buy_predict_questionnaire.csv' 
fields terminated by ';' enclosed by '"' lines terminated by '\r\n' 
FROM plsport_playsport._questionnaire_with_revenue_AND_nickname);


#=============================================
#         action_log url解析的SQL
#=============================================
CREATE TABLE actionlog._user_log_stevenash1520_1 engine = myisam
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
INTO outfile 'C:/Users/1-7_ASUS/Desktop/user_log.csv' 
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM actionlog._user_log_stevenash1520_1;


#===========================================================================================
#    購牌位置代碼解析
#    需要的TABLEs
#    (1)predict_buyer
#    (2)predict_seller
#    (3)predict_buyer_cons_split
#===========================================================================================
    use plsport_playsport;
    drop TABLE if exists plsport_playsport._predict_buyer;
    drop TABLE if exists plsport_playsport._predict_buyer_with_cons;

    #先predict_buyer + predict_buyer_cons_split
    CREATE TABLE plsport_playsport._predict_buyer engine = myisam
    SELECT a.id, a.buyerid, a.id_bought, a.buy_date , a.buy_price, b.position, b.cons, b.allianceid
    FROM plsport_playsport.predict_buyer a LEFT JOIN plsport_playsport.predict_buyer_cons_split b on a.id = b.id_predict_buyer
    WHERE a.buy_price <> 0
    AND a.buy_date between '2014-03-04 00:00:00' AND '2016-12-31 23:59:59'; #2014/03/04是開始有購牌追蹤代碼的日子

        ALTER TABLE plsport_playsport._predict_buyer ADD INDEX (`id_bought`);  

    #再join predict_seller
    CREATE TABLE plsport_playsport._predict_buyer_with_cons engine = myisam
    SELECT c.id, c.buyerid, c.id_bought, d.sellerid ,c.buy_date , c.buy_price, c.position, c.cons, c.allianceid
    FROM plsport_playsport._predict_buyer c LEFT JOIN plsport_playsport.predict_seller d on c.id_bought = d.id
    ORDER BY buy_date DESC;

#version 2 (只有看單月的收益)
SELECT b.p, sum(b.revenue) as revenue
FROM (
    SELECT a.buy_date, a.position, a.revenue, 
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
    FROM (
        SELECT buy_date, position, sum(buy_price) as revenue 
        FROM plsport_playsport._predict_buyer_with_cons
        WHERE buy_date between '2014-04-19 00:00:00' AND '2014-04-30 23:59:59'
        GROUP BY position) as a) as b
GROUP BY b.p 
ORDER BY b.revenue DESC;

#對照收益金額是否有誤
SELECT sum(buy_price)
FROM plsport_playsport._predict_buyer
WHERE buy_date between '2014-04-28 00:00:00' AND '2014-04-29 23:59:59';

CREATE TABLE plsport_playsport._revenue_made_by_position engine = myisam
SELECT a.d, a.p, sum(a.price) as revenue
FROM (
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
GROUP BY a.d, a.p;


#===========================================================================================
#    2014/4/29
#    個人頁的預測表格分析
#    
#    實驗觀察區間: 2014/4/15~5/7
#    組別: 1,2,3
#===========================================================================================

#簡單的觀察
use plsport_playsport;

drop TABLE if exists plsport_playsport._member_with_group;
drop TABLE if exists plsport_playsport._predict_buyer_visitmember_predict_TABLE;
drop TABLE if exists plsport_playsport._predict_buyer_visitmember_predict_TABLE_with_group;

CREATE TABLE plsport_playsport._member_with_group engine = myisam
SELECT ((id%10)+1) as g, userid 
FROM plsport_playsport.member;

CREATE TABLE plsport_playsport._predict_buyer_visitmember_predict_TABLE engine = myisam
SELECT buyerid, sum(buy_price) as spent, count(buy_price) as spent_times #消費者在某段期間內的購買總金額和總次數
FROM plsport_playsport.predict_buyer #購買預測的消費者
WHERE buy_date between '2014-04-15 00:00:00' AND '2014-05-07 23:59:59'
AND buy_price <> 0
GROUP BY buyerid;

    ALTER TABLE plsport_playsport._member_with_group ADD INDEX (`userid`); 
    ALTER TABLE plsport_playsport._predict_buyer_visitmember_predict_TABLE ADD INDEX (`buyerid`);

CREATE TABLE plsport_playsport._predict_buyer_visitmember_predict_TABLE_with_group engine = myisam
SELECT a.buyerid, a.spent, a.spent_times, b.g
FROM plsport_playsport._predict_buyer_visitmember_predict_TABLE a LEFT JOIN plsport_playsport._member_with_group b on a.buyerid = b.userid;

SELECT 'buyerid', 'spent', 'spent_times', 'g' UNION (
SELECT buyerid, spent, spent_times, g
INTO outfile 'C:/proc/r/abtest/predict_buyer_visitmember_predict_TABLE_with_group.csv' 
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM plsport_playsport._predict_buyer_visitmember_predict_TABLE_with_group);


# =================================================================================================
# 
# 2014/5/16 靜怡購牌專區MVP名單任務
# 要直接找人來公司訪談, 所以要對映到居住地
# 居住地的資料有:
#   (1)udata
#   (2)user_living_city
# 
# =================================================================================================

CREATE TABLE plsport_playsport._mycity_FROM_user_living_city engine = myisam
SELECT userid, city, 
       (case when (city = 14) then 'TNN'
             when (city = 16) then 'KHH'
             when (city = 18) then 'PNG' end ) as city1
FROM plsport_playsport.user_living_city
WHERE action=1 AND city in (14,16,18);

CREATE TABLE plsport_playsport._mycity_FROM_udata engine = myisam
SELECT userid, city, 
       (case when (city < 16) then 'TNN'
             when (city < 18) then 'KHH'
             when (city = 18) then 'PNG' end ) as city1
FROM plsport_playsport.udata
WHERE city in (14,15,16,17,18);


CREATE TABLE plsport_playsport._mycity engine = myisam
SELECT  * FROM plsport_playsport._mycity_FROM_user_living_city; 
INSERT IGNORE INTO plsport_playsport._mycity SELECT * FROM plsport_playsport._mycity_FROM_udata;

CREATE TABLE plsport_playsport._mycity1 engine = myisam
SELECT userid, city, city1, count(userid) as c 
FROM plsport_playsport._mycity
GROUP BY userid, city, city1;

CREATE TABLE plsport_playsport._mycity2 engine = myisam
SELECT userid, city, city1 
FROM plsport_playsport._mycity1
GROUP BY userid;

CREATE TABLE plsport_playsport._mycity_order_data engine = myisam
SELECT userid, sum(price) as revenue 
FROM plsport_playsport.order_data
WHERE sellconfirm = 1
AND CREATEon between '2014-02-01 00:00:00' AND '2014-05-31 23:59:59'
GROUP BY userid;

CREATE TABLE plsport_playsport._mycity3 engine = myisam
SELECT a.userid, a.city, a.city1, b.revenue
FROM plsport_playsport._mycity2 a LEFT JOIN plsport_playsport._mycity_order_data b on a.userid = b.userid
WHERE revenue is not null;

CREATE TABLE plsport_playsport._users_daily_pv_buy_predict engine = myisam
SELECT userid, sum(pv_buy_predict) as pv_buy_predict 
FROM actionlog_users_pv._users_daily_pv_buy_predict
GROUP BY userid;

CREATE TABLE plsport_playsport._mycity4 engine = myisam
SELECT a.userid, a.city, a.city1, a.revenue, b.pv_buy_predict
FROM plsport_playsport._mycity3 a LEFT JOIN plsport_playsport._users_daily_pv_buy_predict b on a.userid = b.userid
WHERE pv_buy_predict is not null;

ALTER TABLE  `_mycity4` CHANGE  `userid`  `userid` VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

CREATE TABLE plsport_playsport._mycity5 engine = myisam
SELECT a.userid, b.nickname, a.city, a.city1, a.revenue, a.pv_buy_predict 
FROM plsport_playsport._mycity4 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

CREATE TABLE plsport_playsport._last_time_login engine = myisam
SELECT userid, max(signin_time) as signin_time 
FROM plsport_playsport.member_signin_log_archive
GROUP BY userid;

ALTER TABLE  `_last_time_login` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

CREATE TABLE plsport_playsport._mycity6 engine = myisam
SELECT a.userid, a.nickname, a.city, a.city1, a.revenue, a.pv_buy_predict, b.signin_time
FROM plsport_playsport._mycity5 a LEFT JOIN plsport_playsport._last_time_login b on a.userid = b.userid;

SELECT * FROM plsport_playsport._mycity6
WHERE city1 = 'KHH';

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

CREATE TABLE actionlog._temp_action_201312 engine = myisam SELECT a.userid, a.uri, a.time, a.platform_type 
FROM actionlog.action_201312 a inner join plsport_playsport._mycity6 b on a.userid = b.userid;
CREATE TABLE actionlog._temp_action_201401 engine = myisam SELECT a.userid, a.uri, a.time, a.platform_type 
FROM actionlog.action_201401 a inner join plsport_playsport._mycity6 b on a.userid = b.userid;
CREATE TABLE actionlog._temp_action_201402 engine = myisam SELECT a.userid, a.uri, a.time, a.platform_type 
FROM actionlog.action_201402 a inner join plsport_playsport._mycity6 b on a.userid = b.userid;
CREATE TABLE actionlog._temp_action_201403 engine = myisam SELECT a.userid, a.uri, a.time, a.platform_type 
FROM actionlog.action_201403 a inner join plsport_playsport._mycity6 b on a.userid = b.userid;
CREATE TABLE actionlog._temp_action_201404 engine = myisam SELECT a.userid, a.uri, a.time, a.platform_type 
FROM actionlog.action_201404 a inner join plsport_playsport._mycity6 b on a.userid = b.userid;
CREATE TABLE actionlog._temp_action_201405 engine = myisam SELECT a.userid, a.uri, a.time, a.platform_type 
FROM actionlog.action_201405 a inner join plsport_playsport._mycity6 b on a.userid = b.userid;
CREATE TABLE actionlog._temp_action_201406 engine = myisam SELECT a.userid, a.uri, a.time, a.platform_type 
FROM actionlog.action_201406 a inner join plsport_playsport._mycity6 b on a.userid = b.userid;
CREATE TABLE actionlog._temp_action_201407 engine = myisam SELECT a.userid, a.uri, a.time, a.platform_type 
FROM actionlog.action_201407 a inner join plsport_playsport._mycity6 b on a.userid = b.userid;

CREATE TABLE actionlog._temp_action engine = myisam SELECT * FROM actionlog._temp_action_201312;
INSERT IGNORE INTO actionlog._temp_action SELECT * FROM actionlog._temp_action_201401;
INSERT IGNORE INTO actionlog._temp_action SELECT * FROM actionlog._temp_action_201402;
INSERT IGNORE INTO actionlog._temp_action SELECT * FROM actionlog._temp_action_201403;
INSERT IGNORE INTO actionlog._temp_action SELECT * FROM actionlog._temp_action_201404;
INSERT IGNORE INTO actionlog._temp_action SELECT * FROM actionlog._temp_action_201405;
INSERT IGNORE INTO actionlog._temp_action SELECT * FROM actionlog._temp_action_201406;
INSERT IGNORE INTO actionlog._temp_action SELECT * FROM actionlog._temp_action_201407;

use plsport_playsport;

CREATE TABLE plsport_playsport._mycity7 engine = myisam
SELECT userid, platform_type, count(userid) as c
FROM actionlog._temp_action
GROUP BY userid, platform_type;

CREATE TABLE plsport_playsport._mycity7_desktop engine = myisam
SELECT a.userid, a.p, sum(a.c) as c_desktop
FROM (
    SELECT userid, platform_type, 
        (case when (platform_type = 1) then '1' 
              when (platform_type = 2) then '2' else '2' end) as p, c
    FROM plsport_playsport._mycity7) as a
WHERE a.p = '1'
GROUP BY a.userid, a.p;

CREATE TABLE plsport_playsport._mycity7_mobile engine = myisam
SELECT a.userid, a.p, sum(a.c) as c_mobile
FROM (
    SELECT userid, platform_type, 
        (case when (platform_type = 1) then '1' 
              when (platform_type = 2) then '2' else '2' end) as p, c
    FROM plsport_playsport._mycity7) as a
WHERE a.p = '2'
GROUP BY a.userid, a.p;

CREATE TABLE plsport_playsport._mycity8 engine = myisam
SELECT c.userid, c.nickname, c.city1, c.revenue, c.pv_buy_predict, c.signin_time, c.c_desktop, d.c_mobile
FROM (
    SELECT a.userid, a.nickname, a.city, a.city1, a.revenue, a.pv_buy_predict, a.signin_time, b.c_desktop
    FROM plsport_playsport._mycity6 a LEFT JOIN plsport_playsport._mycity7_desktop b on a.userid = b.userid) as c
    LEFT JOIN plsport_playsport._mycity7_mobile as d on c.userid = d.userid
WHERE c.city1 = 'KHH';

# ==================================================
# 2014/5/26 追加任務 - 要補上購牌專區的左右區塊pv
# ==================================================

CREATE TABLE actionlog._temp_action_201405 engine = myisam
SELECT userid, substr(uri,locate('rp=',uri),length(uri)) as p, time
FROM actionlog.action_201405
WHERE uri LIKE '%rp=BZ%'
AND userid <> '';

CREATE TABLE actionlog._temp_action_201404 engine = myisam
SELECT userid, substr(uri,locate('rp=',uri),length(uri)) as p, time
FROM actionlog.action_201404
WHERE uri LIKE '%rp=BZ%'
AND userid <> '';

CREATE TABLE actionlog._temp_action_201404_05_buypredict engine = myisam SELECT * FROM actionlog._temp_action_201404;
INSERT IGNORE INTO actionlog._temp_action_201404_05_buypredict SELECT * FROM actionlog._temp_action_201405;
drop TABLE actionlog._temp_action_201405, actionlog._temp_action_201404;

CREATE TABLE actionlog._temp_action_201404_05_buypredict_1 engine = myisam
SELECT * 
FROM actionlog._temp_action_201404_05_buypredict
WHERE right(p,1) <> '.'
AND p <> 'rp=BZ_RCTB'
AND length(p) < 15;

CREATE TABLE actionlog._temp_action_201404_05_buypredict_2 engine = myisam
SELECT userid, p, time, (case when (p = 'rp=BZ_MF') then 'area_L'
                              when (p = 'rp=BZ_SK') then 'area_L' else 'area_R' end) as p1
FROM actionlog._temp_action_201404_05_buypredict_1;


# 左邊區塊
CREATE TABLE actionlog._user_buypredict_pv_area_L
SELECT userid, count(userid) as pv_area_L 
FROM actionlog._temp_action_201404_05_buypredict_2
WHERE p1 = 'area_L'
GROUP BY userid;

# 右邊區塊
CREATE TABLE actionlog._user_buypredict_pv_area_R
SELECT userid, count(userid) as pv_area_R 
FROM actionlog._temp_action_201404_05_buypredict_2
WHERE p1 = 'area_R'
GROUP BY userid;


SELECT c.userid, c.nickname, c.city1, c.revenue, c.pv_buy_predict, c.signin_time, c.c_desktop, c.c_mobile, c.pv_area_L, d.pv_area_R
FROM (
    SELECT a.userid, a.nickname, a.city1, a.revenue, a.pv_buy_predict, a.signin_time, a.c_desktop, a.c_mobile, b.pv_area_L
    FROM plsport_playsport._mycity8 a LEFT JOIN actionlog._user_buypredict_pv_area_L b on a.userid = b.userid) c
    LEFT JOIN actionlog._user_buypredict_pv_area_R d on c.userid = d.userid;



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

CREATE TABLE plsport_playsport._order_data_redeem_level engine = myisam
SELECT a.userid, a.y, a.m, sum(price) as redeem
FROM (
    SELECT userid, CREATEon, substr(CREATEon,1,4) as y, substr(CREATEon,1,7) as m, price, payway
    FROM plsport_playsport.order_data
    WHERE payway in (1,2,3,4,5,6,9,10) 
    AND sellconfirm = 1) as a
GROUP BY a.userid, a.y, a.m;

CREATE TABLE plsport_playsport._order_data_redeem_level_1 engine = myisam
SELECT a.userid, b.nickname, b.CREATEon as join_date ,a.y, a.m, a.redeem
FROM plsport_playsport._order_data_redeem_level a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

#-     時間維度可以 a. 開站至今。b. 依年度
CREATE TABLE plsport_playsport._order_data_redeem_level_all_time engine = myisam
SELECT a.userid, a.nickname, a.join_date ,a.total_redeem
FROM (
    SELECT userid, nickname, join_date, sum(redeem) as total_redeem
    FROM plsport_playsport._order_data_redeem_level_1
    GROUP BY userid) as a
ORDER BY a.total_redeem DESC;

#-     時間維度可以 a. 開站至今。b. 依年度
CREATE TABLE plsport_playsport._order_data_redeem_level_by_year engine = myisam
SELECT a.userid, a.nickname, a.join_date, a.y, a.total_redeem
FROM (
    SELECT userid, nickname, join_date, y, sum(redeem) as total_redeem
    FROM plsport_playsport._order_data_redeem_level_1
    GROUP BY userid, y) as a
ORDER BY a.total_redeem DESC;

ALTER TABLE  `_order_data_redeem_level_all_time` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  `_order_data_redeem_level_by_year` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

    SELECT 'userid', 'nickname', 'join_date', 'total_redeem' UNION (
    SELECT *
    INTO outfile 'C:/Users/1-7_ASUS/Desktop/_order_data_redeem_level_all_time.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._order_data_redeem_level_all_time);

    SELECT 'userid', 'nickname', 'join_date', 'y','total_redeem' UNION (
    SELECT *
    INTO outfile 'C:/Users/1-7_ASUS/Desktop/_order_data_redeem_level_by_year.csv' 
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


            SELECT 'userid', 'join_date', 'total_redeem' UNION (
            SELECT userid, join_date, total_redeem
            INTO outfile 'C:/Users/1-7_ASUS/Desktop/_order_data_redeem_level_all_time.csv' 
            fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
            FROM plsport_playsport._order_data_redeem_level_all_time);

            SELECT 'userid', 'join_date', 'y','total_redeem' UNION (
            SELECT userid, join_date, y, total_redeem
            INTO outfile 'C:/Users/1-7_ASUS/Desktop/_order_data_redeem_level_by_year.csv' 
            fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
            FROM plsport_playsport._order_data_redeem_level_by_year);

            ALTER TABLE plsport_playsport._order_data_redeem_level_all_time ADD INDEX (`userid`);
            ALTER TABLE plsport_playsport._last_signin ADD INDEX (`userid`);

            CREATE TABLE plsport_playsport._last_signin engine = myisam # 最近一次登入
            SELECT userid, max(signin_time) as last_signin
            FROM plsport_playsport.member_signin_log_archive
            GROUP BY userid;

            SELECT a.userid, a.nickname, a.join_date, b.last_signin, a.total_redeem  
            FROM plsport_playsport._order_data_redeem_level_all_time a LEFT JOIN plsport_playsport._last_signin b on a.userid = b.userid
            ORDER BY a.total_redeem DESC
            limit 0, 100;


#-     b. 一年內儲值總金額
CREATE TABLE plsport_playsport._order_data_redeem_within_one_year engine = myisam
SELECT b.userid, sum(b.redeem) as redeem_in_one_year
FROM (
    SELECT a.userid, a.y, a.m, sum(price) as redeem
    FROM (
        SELECT userid, CREATEon, substr(CREATEon,1,4) as y, substr(CREATEon,1,7) as m, price, payway
        FROM plsport_playsport.order_data
        WHERE payway in (1,2,3,4,5,6,9,10) 
        AND sellconfirm = 1
        AND CREATEon between subdate(now(),356) AND now() ) as a
    GROUP BY a.userid, a.y, a.m) as b
GROUP BY b.userid;

ALTER TABLE  `_order_data_redeem_within_one_year` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

#-     c. 最大筆儲值金額
CREATE TABLE plsport_playsport._order_data_redeem_max_AND_min engine = myisam
SELECT userid, min(price) as min_redeem, max(price) as max_redeem
FROM plsport_playsport.order_data
WHERE payway in (1,2,3,4,5,6,9,10) 
AND sellconfirm = 1
GROUP BY userid;

ALTER TABLE  `_order_data_redeem_max_AND_min` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

#-     d. 上次登入時間
CREATE TABLE plsport_playsport._last_time_login engine = myisam
SELECT userid, max(signin_time) as signin_time 
FROM plsport_playsport.member_signin_log_archive
GROUP BY userid;

ALTER TABLE  `_last_time_login` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

    ALTER TABLE plsport_playsport._order_data_redeem_within_one_year ADD INDEX (`userid`);
    ALTER TABLE plsport_playsport._order_data_redeem_max_AND_min ADD INDEX (`userid`);
    ALTER TABLE plsport_playsport._last_time_login ADD INDEX (`userid`);

# 最後名單-完成
CREATE TABLE plsport_playsport._order_data_redeem_full_list engine = myisam
SELECT e.userid, e.nickname, e.join_date, e.total_redeem, e.redeem_in_one_year, e.min_redeem, e.max_redeem, f.signin_time
FROM (
    SELECT c.userid, c.nickname, c.join_date, c.total_redeem, c.redeem_in_one_year, d.min_redeem, d.max_redeem
    FROM (
        SELECT a.userid, a.nickname, a.join_date, a.total_redeem, b.redeem_in_one_year
        FROM plsport_playsport._order_data_redeem_level_all_time a LEFT JOIN plsport_playsport._order_data_redeem_within_one_year b on a.userid = b.userid) as c
        LEFT JOIN plsport_playsport._order_data_redeem_max_AND_min as d on c.userid = d.userid) as e 
    LEFT JOIN plsport_playsport._last_time_login as f on e.userid = f.userid;

ALTER TABLE  `_order_data_redeem_full_list` CHANGE  `nickname`  `nickname` CHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ;

SELECT 'userid', 'nickname', '加入會員', '總儲值', '近一年儲值', '最低儲值', '最高儲值', '最後一次登入時間' UNION (
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_order_data_redeem_full_list.csv' 
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
CREATE TABLE plsport_playsport._order_data_card_user engine = myisam
SELECT userid, CREATEon, substr(CREATEon,1,4) as y, substr(CREATEon,1,7) as m, price, payway
FROM plsport_playsport.order_data
WHERE payway in (1,2,3,4,5,6,9,10) 
AND sellconfirm = 1
AND CREATEon between '2012-01-01 00:00:00' AND '2014-04-30 23:59:59';

# 依年度來算
SELECT y, payway, sum(price) as total_redeem 
FROM plsport_playsport._order_data_card_user
GROUP BY y, payway;

# 總共有多少人儲值過 - 11831
SELECT count(a.userid) 
FROM (
    SELECT userid, sum(price) 
    FROM plsport_playsport._order_data_card_user
    GROUP BY userid) as a;

# 總共有多少人儲值過(用信用卡) - 2807
SELECT count(a.userid)
FROM (
    SELECT userid, sum(price)  
    FROM plsport_playsport._order_data_card_user
    WHERE payway = 6
    GROUP BY userid) as a;

# a
CREATE TABLE plsport_playsport._order_data_card_user_a engine = myisam
SELECT a.userid, a.total_redeem
FROM (
    SELECT userid, sum(price) as total_redeem 
    FROM plsport_playsport._order_data_card_user
    GROUP BY userid) as a 
ORDER BY a.total_redeem DESC;

# b
CREATE TABLE plsport_playsport._order_data_card_user_b engine = myisam
SELECT a.userid, a.pay, (case when (a.pay is not null) then 'credit' end ) as ifpaycredit
FROM (
    SELECT userid, sum(price) as pay
    FROM plsport_playsport._order_data_card_user
    WHERE payway = 1
    GROUP BY userid) as a;

# a LEFT JOIN b = c
CREATE TABLE plsport_playsport._order_data_card_user_c engine = myisam
SELECT a.userid, a.total_redeem, b.pay, b.ifpaycredit
FROM plsport_playsport._order_data_card_user_a as a LEFT JOIN plsport_playsport._order_data_card_user_b  as b on a.userid = b.userid;

SELECT 'userid', 'total_redeem', 'pay', 'ifpaycredit' UNION (
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_order_data_card_user_c.csv' 
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
CREATE TABLE plsport_playsport._gobucket_count engine = myisam
SELECT b.userid, b.nickname, count(b.userid) as gobucket_count
FROM (
    SELECT a.userid, a.nickname, a.d, count(a.userid) as c
    FROM (
        SELECT userid, nickname, subjectid, date(startdate) as d 
        FROM plsport_playsport.gobucket
        WHERE type in (1,2,3,99)) as a
    GROUP BY a.userid, a.nickname, a.d) as b
GROUP BY b.userid, b.nickname;

CREATE TABLE plsport_playsport._gobucket_forever engine = myisam
SELECT c.userid, c.nickname, (case when (c.gobucket_forever > 0) then 'yes' end) as gobucket_forever
FROM (
    SELECT b.userid, b.nickname, count(b.userid) as gobucket_forever
    FROM (
        SELECT a.userid, a.nickname, a.d, count(a.userid) as c
        FROM (
            SELECT userid, nickname, subjectid, date(startdate) as d 
            FROM plsport_playsport.gobucket
            WHERE type in (99)) as a
        GROUP BY a.userid, a.nickname, a.d) as b
    GROUP BY b.userid, b.nickname) as c;

CREATE TABLE plsport_playsport._gobucket_count_with_forever engine = myisam
SELECT a.userid, a.nickname, a.gobucket_count, b.gobucket_forever
FROM plsport_playsport._gobucket_count a LEFT JOIN plsport_playsport._gobucket_forever b on a.userid = b.userid;

drop TABLE plsport_playsport._gobucket_count, plsport_playsport._gobucket_forever;

# -------------------------------------------------------------------------------------------------
# b:分身 (是否有分身記錄)
CREATE TABLE plsport_playsport._sell_deny engine = myisam
SELECT master_userid 
FROM plsport_playsport.sell_deny;

INSERT IGNORE INTO plsport_playsport._sell_deny SELECT slave_userid FROM plsport_playsport.sell_deny;

CREATE TABLE plsport_playsport._sell_deny_remove_duplicate engine = myisam
SELECT master_userid as multiid, count(master_userid) as c
FROM plsport_playsport._sell_deny
GROUP BY master_userid;

# -------------------------------------------------------------------------------------------------
# c:住址1 - exchange_validate
CREATE TABLE plsport_playsport._city_info engine = myisam
SELECT userid, city FROM plsport_playsport.exchange_validate;

# 住址2 - user_living_city
INSERT IGNORE INTO plsport_playsport._city_info
SELECT userid, city
FROM plsport_playsport.user_living_city
WHERE action = 1 ;

# 住址3 - udata
INSERT IGNORE INTO plsport_playsport._city_info
SELECT userid, city
FROM plsport_playsport.udata;

CREATE TABLE plsport_playsport._city_info_ok engine = myisam
SELECT userid, city
FROM plsport_playsport._city_info
GROUP BY userid;

CREATE TABLE plsport_playsport._city_info_ok_with_chinese engine = myisam
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

drop TABLE plsport_playsport._city_info_ok, plsport_playsport._city_info;

# -------------------------------------------------------------------------------------------------
# a+b+c
ALTER TABLE  `_city_info_ok_with_chinese` CHANGE  `userid`  `userid` VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  `_sell_deny_remove_duplicate` CHANGE  `multiid`  `multiid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  `_gobucket_count_with_forever` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

CREATE TABLE plsport_playsport._multiid_city_sell_deny engine = myisam
SELECT e.id, e.userid, e.g, e.multi_id, e.city1, f.gobucket_count, f.gobucket_forever
FROM (
    SELECT c.id, c.userid, c.g, c.multi_id, d.city1
    FROM (
        SELECT a.id, a.userid, a.g, b.c as multi_id
        FROM user_cluster.cluster_with_real_userid a LEFT JOIN plsport_playsport._sell_deny_remove_duplicate b on a.userid = b.multiid) c
        LEFT JOIN plsport_playsport._city_info_ok_with_chinese d on c.userid = d.userid) e
    LEFT JOIN plsport_playsport._gobucket_count_with_forever f on e.userid = f.userid;

# 輸出csv
SELECT 'id', 'userid', 'g', 'multi_id', 'city1', 'gobucket_count', 'gobucket_forever' UNION (
SELECT * 
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_multiid_city_sell_deny.csv'
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
CREATE TABLE plsport_playsport._analysis_king engine = myisam 
SELECT userid, subjectid, got_time, gamedate, 
       (case when (subjectid is not null) then 'y' end) as isanalysispost
FROM plsport_playsport.analysis_king
WHERE got_time between '2011-05-01 00:00:00' AND '2014-05-25 23:59:59'
ORDER BY got_time DESC;

CREATE TABLE plsport_playsport._analysis_king_count engine = myisam 
SELECT a.userid, b.nickname, date(b.CREATEon) as join_date, a.analysis_c
FROM (
    SELECT userid, count(userid) as analysis_c 
    FROM plsport_playsport._analysis_king
    GROUP BY userid) a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

SELECT 'userid', 'nickname','analysis_king_count' UNION (
SELECT * 
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_analysis_king_count.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM plsport_playsport._analysis_king_count);

# 2014-06-09分析問卷的任務

CREATE TABLE plsport_playsport._analysis_king_count_1 engine = myisam
SELECT * FROM plsport_playsport._analysis_king_count
WHERE analysis_c > 4
ORDER BY analysis_c DESC;

ALTER TABLE  `_analysis_king_count_1` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  `_analysis_king_count_1` CHANGE  `nickname`  `nickname` CHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ;

CREATE TABLE plsport_playsport._analysis_king_count_2 engine = myisam
SELECT a.userid, a.nickname, a.join_date, a.analysis_c, b.spend_minute, b.iswillingto, b.ruleaggrement, b.rulesuggestion, b.ruleencouraged, b.price, b.reasonstopwriting
FROM plsport_playsport._analysis_king_count_1 a LEFT JOIN plsport_playsport.questionnaire_sellanalysis_answer b on a.userid = b.userid;


UPDATE plsport_playsport._analysis_king_count_2 SET rulesuggestion = TRIM(rulesuggestion);  #刪掉空白字完
update plsport_playsport._analysis_king_count_2 SET rulesuggestion = replace(rulesuggestion, '.',''); 
update plsport_playsport._analysis_king_count_2 SET rulesuggestion = replace(rulesuggestion, ';','');
update plsport_playsport._analysis_king_count_2 SET rulesuggestion = replace(rulesuggestion, '/','');
update plsport_playsport._analysis_king_count_2 SET rulesuggestion = replace(rulesuggestion, '\\','_');
update plsport_playsport._analysis_king_count_2 SET rulesuggestion = replace(rulesuggestion, '"','');
update plsport_playsport._analysis_king_count_2 SET rulesuggestion = replace(rulesuggestion, '&','');
update plsport_playsport._analysis_king_count_2 SET rulesuggestion = replace(rulesuggestion, '#','');
update plsport_playsport._analysis_king_count_2 SET rulesuggestion = replace(rulesuggestion, ' ','');
update plsport_playsport._analysis_king_count_2 SET rulesuggestion = replace(rulesuggestion, '\r','');
update plsport_playsport._analysis_king_count_2 SET rulesuggestion = replace(rulesuggestion, '\n','');

SELECT 'userid', 'nickname','join_date','analysis_count','spend_minute','iswillingto','ruleaggrement','rulesuggestion','ruleencouraged','price','reasonstopwriting' UNION (
SELECT * 
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_analysis_king_count_2.csv'
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

CREATE database textcampaign;

use textcampaign;

drop TABLE if exists _list1, _list2, _list3, _list4, _recent_login, _who_dont_want_text; 

# 主名單: 近550天內曾經儲值過的人, 並有符合電話格式(10碼)
CREATE TABLE textcampaign._list1 engine = myisam
SELECT a.userid, a.phone, sum(a.price) as total_redeem
FROM (
    SELECT userid, phone, CREATEon, price 
    FROM plsport_playsport.order_data
    WHERE sellconfirm = 1 AND payway in (1,2,3,4,5,6,9,10)
    AND CREATEon between subdate(now(),570) AND now()) as a # 一年半內有儲值過
WHERE length(phone) = 10 AND substr(phone,1,2) = '09' AND phone regexp '^[[:digit:]]{10}$'
GROUP BY a.userid
ORDER BY a.userid;

                # (1)準備簡報用的而已 2015-02-11社群會議
                CREATE TABLE textcampaign._all_phone_list engine = myisam
                SELECT a.userid, a.phone, sum(a.price) as total_redeem
                FROM (
                    SELECT userid, phone, CREATEon, price 
                    FROM plsport_playsport.order_data
                    WHERE sellconfirm = 1 AND payway in (1,2,3,4,5,6,9,10)
                    AND CREATEon between subdate(now(),9999) AND now()) as a # 一年半內有儲值過
                WHERE length(phone) = 10 AND substr(phone,1,2) = '09' AND phone regexp '^[[:digit:]]{10}$'
                GROUP BY a.userid
                ORDER BY a.userid;
                
                # (2)       
                CREATE TABLE textcampaign._last_time_login engine = myisam
                SELECT userid, date(max(signin_time)) as last_time_login
                FROM plsport_playsport.member_signin_log_archive
                GROUP BY userid;

                # (3) 
                CREATE TABLE textcampaign._all_phone_list_with_join engine = myisam
                SELECT a.userid, b.CREATEon, a.phone, a.total_redeem 
                FROM textcampaign._all_phone_list a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

                ALTER TABLE textcampaign._all_phone_list_with_join convert to character SET utf8 collate utf8_general_ci;
                ALTER TABLE textcampaign._last_time_login convert to character SET utf8 collate utf8_general_ci;
                ALTER TABLE textcampaign._all_phone_list_with_join ADD INDEX (`userid`);
                ALTER TABLE textcampaign._last_time_login ADD INDEX (`userid`);

                CREATE TABLE textcampaign._all_phone_list_with_join_last engine = myisam
                SELECT a.userid, date(a.CREATEon) as join_date, b.last_time_login, a.phone, a.total_redeem 
                FROM textcampaign._all_phone_list_with_join a LEFT JOIN textcampaign._last_time_login b on a.userid = b.userid;

                CREATE TABLE textcampaign._all_phone_list_with_join_last_1 engine = myisam
                SELECT userid, substr(join_date,1,7) as j, substr(last_time_login,1,7) as d, phone, total_redeem 
                FROM textcampaign._all_phone_list_with_join_last;

                # ok了
                SELECT j, count(userid) as c 
                FROM textcampaign._all_phone_list_with_join_last_1
                GROUP BY j;

                SELECT d, count(userid) as c 
                FROM textcampaign._all_phone_list_with_join_last_1
                GROUP BY d;


# 拒收簡訊名單
CREATE TABLE textcampaign._who_dont_want_text engine = myisam
SELECT a.phone
FROM (
    SELECT userid, phone 
    FROM plsport_playsport.order_data
    WHERE receive_ad = 0) as a
GROUP BY a.phone;

# 近3個月內有登入的人(如果人數很多的話, 視情況可修改為近1個月)
CREATE TABLE textcampaign._recent_login engine = myisam
SELECT a.userid, count(a.userid) as c, (case when (a.userid is not null) then 'yes' end) as recent_login
FROM (
    SELECT * 
    FROM plsport_playsport.member_signin_log_archive
    WHERE signin_time between subdate(now(),90) AND now() # 設定為3個月
    ORDER BY signin_time) as a
GROUP BY a.userid;

# 每個人最後一次登入是何日
CREATE TABLE textcampaign._last_time_login engine = myisam
SELECT userid, date(max(signin_time)) as last_time_login
FROM plsport_playsport.member_signin_log_archive
GROUP BY userid;

    ALTER TABLE textcampaign._list1 CHANGE `userid` `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
    ALTER TABLE textcampaign._recent_login CHANGE `userid` `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
    ALTER TABLE textcampaign._last_time_login CHANGE `userid` `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
    ALTER TABLE textcampaign._last_time_login ADD INDEX (`userid`);

# 主名單: 加入誰近3個月內有登入
CREATE TABLE textcampaign._list2 engine = myisam
SELECT a.userid, a.phone, a.total_redeem, b.recent_login
FROM textcampaign._list1 a LEFT JOIN textcampaign._recent_login b on a.userid = b.userid;

# 主名單: 排除掉拒收簡訊名單
CREATE TABLE textcampaign._list3 engine = myisam
SELECT a.userid, a.phone, total_redeem, a.recent_login
FROM textcampaign._list2 a LEFT JOIN textcampaign._who_dont_want_text b on a.phone = b.phone
WHERE b.phone is null;

# 主名單: 排除最近有登入的人
CREATE TABLE textcampaign._list4 engine = myisam
SELECT * 
FROM textcampaign._list3
WHERE recent_login is null;

# 主名單: 完整版(加入使用者id, 和最近一次登入日期)
CREATE TABLE textcampaign._list5 engine = myisam
SELECT c.phone, d.id, c.total_redeem, c.last_time_login, (case when (d.id is not null) then 'retention_201406' end) as text_campaign, ((d.id%2)+1) as abtest_group
FROM (
    SELECT a.userid, a.phone, a.total_redeem, b.last_time_login
    FROM textcampaign._list4 a LEFT JOIN textcampaign._last_time_login b on a.userid = b.userid) as c 
LEFT JOIN plsport_playsport.member as d on c.userid = d.userid; 

# 檢查名單數用
CREATE TABLE textcampaign._count engine = myisam
SELECT phone, count(id)
FROM textcampaign._list5
GROUP BY phone;


SELECT 'phone', '使用者編號id', '簡訊行銷', '總儲值金額', '最後一次登入',  'abtest組別' UNION (
SELECT phone, id, text_campaign, total_redeem, last_time_login, abtest_group 
INTO outfile 'C:/Users/1-7_ASUS/Desktop/retention_201406.csv'
CHARACTER SET big5 fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM textcampaign._list5);
# 一定要設定為big編碼, yoyo8規定的


# --------------------------------------------
# 8月底了, 開始追蹤 (2014-08-29) 
# 當初是6月2日發送的簡訊 2014-06-02~2014-08-24
# note: 第一次追蹤
# --------------------------------------------

# 開始製作追蹤的名單

CREATE TABLE textcampaign._check_list_1 engine = myisam
SELECT a.phone, a.id, b.userid, a.total_redeem, a.last_time_login, a.text_campaign, a.abtest_group 
FROM textcampaign._list5 a LEFT JOIN plsport_playsport.member b on a.id = b.id;

CREATE TABLE textcampaign._user_spent engine = myisam
SELECT userid, sum(amount) as spent  
FROM plsport_playsport.pcash_log
WHERE date(date) between '2014-06-02' AND '2014-08-24'
AND payed = 1 AND type = 1
GROUP BY userid;

CREATE TABLE textcampaign._user_redeem engine = myisam
SELECT userid, sum(amount) as redeem  
FROM plsport_playsport.pcash_log
WHERE date(date) between '2014-06-02' AND '2014-08-24'
AND payed = 1 AND type in (3,4)
GROUP BY userid;

                CREATE TABLE textcampaign._last_time_login_1 engine = myisam
                SELECT userid, date(signin_time) as d 
                FROM plsport_playsport.member_signin_log_archive
                WHERE date(signin_time) between '2014-06-02' AND '2014-08-24';

                        ALTER TABLE textcampaign._last_time_login_1 ADD INDEX (`userid`);
                        ALTER TABLE textcampaign._last_time_login_1 ADD INDEX (`d`);

                CREATE TABLE textcampaign._last_time_login_2 engine = myisam
                SELECT userid, d, count(userid) as c 
                FROM textcampaign._last_time_login_1
                GROUP BY userid, d;

                CREATE TABLE textcampaign._last_time_login_3 engine = myisam
                SELECT userid, count(d) as signin_days_count
                FROM textcampaign._last_time_login_2
                GROUP BY userid;

                drop TABLE textcampaign._last_time_login_1;
                drop TABLE textcampaign._last_time_login_2;

        ALTER TABLE textcampaign._check_list_1 ADD INDEX (`userid`);
        ALTER TABLE textcampaign._user_spent ADD INDEX (`userid`);
        ALTER TABLE textcampaign._user_redeem ADD INDEX (`userid`);
        ALTER TABLE textcampaign._last_time_login_3 ADD INDEX (`userid`);

CREATE TABLE textcampaign._check_list_2 engine = myisam
SELECT c.phone, c.id, c.userid, c.total_redeem, c.last_time_login, c.text_campaign, c.abtest_group, c.spent, d.redeem
FROM (
    SELECT a.phone, a.id, a.userid, a.total_redeem, a.last_time_login, a.text_campaign, a.abtest_group, b.spent
    FROM textcampaign._check_list_1 a LEFT JOIN textcampaign._user_spent b on a.userid = b.userid) as c
LEFT JOIN textcampaign._user_redeem as d on c.userid = d.userid;

CREATE TABLE textcampaign._check_list_3 engine = myisam
SELECT a.phone, a.id, a.userid, a.total_redeem, a.last_time_login, a.text_campaign, a.abtest_group, a.spent, a.redeem, b.signin_days_count
FROM textcampaign._check_list_2 a LEFT JOIN textcampaign._last_time_login_3 b on a.userid = b.userid;


SELECT a.m, a.abtest_group, sum(spent), sum(redeem)
FROM (
    SELECT substr(last_time_login,1,7) as m, abtest_group, spent, redeem 
    FROM textcampaign._check_list_3) as a
GROUP BY a.m, a.abtest_group;

# ==================NEW任務==================
# 簡訊流失客延任務 (柔雅) 2014-10-15 任務: [201311-E] 簡訊追蹤與短網址 [進行中]
# http://pm.playsport.cc/index.php/tasksComments?tasksId=2269&projectId=11
# TO EDDY
# 
# 下次流失客簡訊發送日期為10/2號，
# 測試的方向為: (1)重覆發送4000(2000/2000) + (2)殺手報牌2000(1000/1000)
# (1)重覆發送(11/03): 與上次相同的名單，發送相同的內容，追蹤成效。
# (2)殺手報牌(10/31): 重新撈一組名單(需排除與"重覆發送"相同名單)，
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
CREATE TABLE textcampaign._list5_to_see_how_many_cANDidate_available engine = myisam
SELECT a.phone, a.id, a.total_redeem, a.last_time_login, a.text_campaign, a.abtest_group, b.abtest_group as abtest_group1
FROM textcampaign._list5 a LEFT JOIN textcampaign.retention_201406_full_list_dont_delete b on a.id = b.id
WHERE b.abtest_group is null;

CREATE TABLE textcampaign._list6 engine = myisam
SELECT phone, id, total_redeem, last_time_login, (case when (text_campaign is not null) then 'retention_201410b' end) as text_campaign, abtest_group 
FROM textcampaign._list5_to_see_how_many_cANDidate_available;


SELECT 'phone', '使用者編號id', '簡訊行銷', '總儲值金額', '最後一次登入',  'abtest組別' UNION (
SELECT phone, id, text_campaign, total_redeem, last_time_login, abtest_group 
INTO outfile 'C:/Users/1-7_ASUS/Desktop/retention_201410b.csv'
CHARACTER SET big5 fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM textcampaign._list6);
# 一定要設定為big編碼, 


# ---------------------------------------------------------------------
# 任務: [201311-E] 簡訊追蹤與短網址 [進行中] (柔雅) 2014-12-30
# http://pm.playsport.cc/index.php/tasksComments?tasksId=2269&projectId=11
# 目的：
# 第一階段：對象是買牌客，讓流失客知道還有一個網站叫玩運彩，有空要回來
# 第二階段：讓流失客付錢
#  
# 目標：
# 第一階段：三個月後，瞭解他們有沒有回到網站，重新登入。
# 第二階段：三個月後，有沒有付錢。
# ----------------------------------------------------------------------

# database: textcampaign
# (1)第一次6月發送的名單:retention_201406_full_list_dont_delete
# (2)第二次10月31日發送的名單: _list6 (殺手報牌)
# (3)拿(1)的名單再於11月3日發送一次   (重覆轟炸)

use textcampaign;

CREATE TABLE textcampaign.retention_20141031_full_list_dont_delete
SELECT * FROM textcampaign._list6;


CREATE TABLE textcampaign._tracklist_0 engine = myisam
SELECT phone, id, text_campaign, abtest_group 
FROM textcampaign.retention_201406_full_list_dont_delete;

INSERT IGNORE INTO textcampaign._tracklist_0
SELECT phone, id, text_campaign, abtest_group 
FROM textcampaign.retention_20141031_full_list_dont_delete;

CREATE TABLE textcampaign._tracklist_1 engine = myisam
SELECT a.phone, a.id, b.userid, a.text_campaign, a.abtest_group, (case when (a.abtest_group=1) then 'sent' else 'hold' end) as abtest
FROM textcampaign._tracklist_0 a LEFT JOIN plsport_playsport.member b on a.id = b.id;

        # 每個人最後一次登入是何日
        CREATE TABLE textcampaign._last_time_login engine = myisam
        SELECT userid, date(max(signin_time)) as last_time_login
        FROM plsport_playsport.member_signin_log_archive
        WHERE signin_time between '2014-06-02 00:00:00' AND '2014-12-31 23:59:59'
        GROUP BY userid;

        # 儲值金額
        CREATE TABLE textcampaign._order_data engine = myisam
        SELECT userid, sum(redeem) as total_redeem
        FROM (
            SELECT userid, amount as redeem, date, substr(date,1,7) as ym, year(date) as y, substr(date,6,2) as m 
            FROM plsport_playsport.pcash_log
            WHERE payed = 1 AND type in (3,4)
            AND date between '2014-06-02 00:00:00' AND '2014-12-31 23:59:59') as a
        GROUP BY a.userid;

        ALTER TABLE textcampaign._tracklist_1     ADD INDEX (`userid`);
        ALTER TABLE textcampaign._last_time_login ADD INDEX (`userid`);
        ALTER TABLE textcampaign._order_data      ADD INDEX (`userid`);

CREATE TABLE textcampaign._tracklist_2 engine = myisam
SELECT a.phone, a.id, a.userid, a.text_campaign, a.abtest_group, a.abtest, b.total_redeem
FROM textcampaign._tracklist_1 a LEFT JOIN textcampaign._order_data b on a.userid = b.userid;

CREATE TABLE textcampaign._tracklist_3 engine = myisam
SELECT a.phone, a.id, a.userid, a.text_campaign, a.abtest_group, a.abtest, a.total_redeem, b.last_time_login
FROM textcampaign._tracklist_2 a LEFT JOIN textcampaign._last_time_login b on a.userid = b.userid;

SELECT text_campaign, abtest, sum(total_redeem) 
FROM textcampaign._tracklist_3
GROUP BY text_campaign, abtest;


# 另一種名單
        # 儲值金額
        CREATE TABLE textcampaign._order_data_1 engine = myisam
        SELECT a.userid, a.d, sum(redeem) as total_redeem
        FROM (
            SELECT userid, amount as redeem, date, substr(date,1,10) as d
            FROM plsport_playsport.pcash_log
            WHERE payed = 1 AND type in (3,4)
            AND date between '2014-06-02 00:00:00' AND '2014-12-31 23:59:59') as a
        GROUP BY a.userid, a.d;


CREATE TABLE textcampaign._tracklist_4_by_date engine = myisam
SELECT a.userid, a.d, a.total_redeem, b.text_campaign, b.abtest
FROM textcampaign._order_data_1 a LEFT JOIN textcampaign._tracklist_1 b on a.userid = b.userid
WHERE b.text_campaign is not null;

CREATE TABLE textcampaign._tracklist_4_by_date_1 engine = myisam
SELECT text_campaign, abtest, d, substr(d,1,7) as m, sum(total_redeem)  as redeem
FROM textcampaign._tracklist_4_by_date
WHERE userid not in ( # 排除掉儲值大戶
                    SELECT a.userid  
                    FROM (
                        SELECT userid, sum(total_redeem) as total_redeem 
                        FROM textcampaign._tracklist_4_by_date
                        GROUP BY userid) as a
                    WHERE a.total_redeem > 20000
                    ORDER BY a.total_redeem DESC)
GROUP BY text_campaign, abtest, d;

SELECT 'text', 'abtest', 'd' ,'m', 'redeem' UNION (
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/text_campaign.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM textcampaign._tracklist_4_by_date_1);


        # 每個人的登入次數-10月後
        CREATE TABLE textcampaign._login_count_after_10 engine = myisam
        SELECT userid, count(signin_time) as login_count
        FROM plsport_playsport.member_signin_log_archive
        WHERE signin_time between '2014-10-30 00:00:00' AND '2014-12-31 23:59:59' # 只看發送簡訊之後的登入數
        GROUP BY userid;

        # 每個人的登入次數-6月後
        CREATE TABLE textcampaign._login_count_after_6 engine = myisam
        SELECT userid, count(signin_time) as login_count
        FROM plsport_playsport.member_signin_log_archive
        WHERE signin_time between '2014-06-02 00:00:00' AND '2014-12-31 23:59:59' # 只看發送簡訊之後的登入數
        GROUP BY userid;

        ALTER TABLE textcampaign._login_count_after_6      ADD INDEX (`userid`);
        ALTER TABLE textcampaign._login_count_after_10     ADD INDEX (`userid`);

        CREATE TABLE textcampaign._login_count engine = myisam
        SELECT a.userid, a.login_count as login_c_6, b.login_count as login_c_10
        FROM textcampaign._login_count_after_6 a LEFT JOIN textcampaign._login_count_after_10 b on a.userid = b.userid;

        CREATE TABLE textcampaign._login_count_1 engine = myisam
        SELECT userid, login_c_6, (case when ( login_c_10 is null) then 0 else login_c_10 end) as login_c_10
        FROM textcampaign._login_count;

        ALTER TABLE textcampaign._login_count_1     ADD INDEX (`userid`);

CREATE TABLE textcampaign._tracklist_1_user_login_count engine = myisam 
SELECT a.phone, a.id, a.userid, a.text_campaign, a.abtest_group, a.abtest, b.login_c_6, b.login_c_10
FROM textcampaign._tracklist_1 a LEFT JOIN textcampaign._login_count_1 b on a.userid = b.userid;

        # 儲值金額-6月後
        CREATE TABLE textcampaign._order_data_6 engine = myisam
        SELECT a.userid, sum(redeem) as total_redeem
        FROM (
            SELECT userid, amount as redeem, date, substr(date,1,10) as d
            FROM plsport_playsport.pcash_log
            WHERE payed = 1 AND type in (3,4)
            AND date between '2014-06-02 00:00:00' AND '2014-12-31 23:59:59') as a
        GROUP BY a.userid;

        # 儲值金額-10月後
        CREATE TABLE textcampaign._order_data_10 engine = myisam
        SELECT a.userid, sum(redeem) as total_redeem
        FROM (
            SELECT userid, amount as redeem, date, substr(date,1,10) as d
            FROM plsport_playsport.pcash_log
            WHERE payed = 1 AND type in (3,4)
            AND date between '2014-10-30 00:00:00' AND '2014-12-31 23:59:59') as a
        GROUP BY a.userid;

        CREATE TABLE textcampaign._order_data_all engine = myisam
        SELECT a.userid, a.total_redeem as redeem_6, b.total_redeem as redeem_10
        FROM textcampaign._order_data_6 a LEFT JOIN textcampaign._order_data_10 b on a.userid = b.userid;

CREATE TABLE textcampaign._tracklist_1_user_login_count1 engine = myisam 
SELECT a.phone, a.id, a.userid, a.text_campaign, a.abtest_group, a.abtest, a.login_c_6, a.login_c_10, b.redeem_6, b.redeem_10
FROM textcampaign._tracklist_1_user_login_count a LEFT JOIN textcampaign._order_data_all b on a.userid = b.userid;


SELECT 'id','text','abtest','login_6','login_10','redeem_6','redeem_10'  UNION (
SELECT id, text_campaign, abtest, login_c_6, login_c_10, redeem_6, redeem_10
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_tracklist_1_user_login_count.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM textcampaign._tracklist_1_user_login_count1);


# ----------------------------------------------------------------------
# 流失客領取兌換券 (柔雅) 2015-01-12
# TO EDDY
# 麻煩請於下周二(1/13號)提供下一次流失客的名單，預計1/14發送。
# 發送方向為: 流失客領取兌換券
# 
# 篩選條件:
#   1.約前一年半的時間內，曾經儲值過
#   2.已有三個月未登入、購買、儲值
#   3.依照儲值總金額排序，越高的優先發送
#   4.每次最多2000筆，匯出csv或txt(供yoyo8發送)
#   5.每一筆有效號碼，不要連續傳送，相隔一個月以上
#   ps.請另外提供一份有id的名單，給工程套入程式使用。
# 任務狀態: 進行中
# ----------------------------------------------------------------------

# 先跑list1~list4

# 主名單: 完整版(加入使用者id, 和最近一次登入日期)
CREATE TABLE textcampaign._list5 engine = myisam
SELECT c.phone, d.id, c.userid, c.total_redeem, c.last_time_login, 
       (case when (d.id is not null) then 'retention_20150114' end) as text_campaign, ((d.id%10)+1) as abtest_group
FROM (
    SELECT a.userid, a.phone, a.total_redeem, b.last_time_login
    FROM textcampaign._list4 a LEFT JOIN textcampaign._last_time_login b on a.userid = b.userid) as c 
LEFT JOIN plsport_playsport.member as d on c.userid = d.userid; 


CREATE TABLE textcampaign._list6 engine = myisam
SELECT phone, id, userid, total_redeem, last_time_login, text_campaign, abtest_group, 
       (case when (abtest_group>6) then 'hold' else 'sent' end) as status # 60:40 發送/不發
FROM textcampaign._list5;

        # 給yoyo8簡訊發送
        SELECT 'phone', '使用者編號id', '簡訊行銷' UNION (
        SELECT phone, id, text_campaign
        INTO outfile 'C:/Users/1-7_ASUS/Desktop/retention_20150114_for_yoyo8.csv'
        CHARACTER SET big5 fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
        FROM textcampaign._list6
        WHERE status = 'sent'); # 只撈出有要發送的
        # 一定要設定為big編碼, yoyo8規定的

        # 給工程部匯入兌換券發送系統
        SELECT '使用者編號id', 'userid' UNION (
        SELECT id, userid
        INTO outfile 'C:/Users/1-7_ASUS/Desktop/retention_20150114_for_software_team.csv'
        fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
        FROM textcampaign._list6
        WHERE status = 'sent'); # 只撈出有要發送的
        
CREATE TABLE textcampaign.retention_20150114_full_list_dont_delete engine = myisam
SELECT * FROM textcampaign._list6;        


# 以下是追蹤的部分 2015-01-26
# 先匯入billrec_playsport_1422255478_簡訊發送結果.txt
use textcampaign;

CREATE TABLE textcampaign._text_sent_status engine = myisam
SELECT concat('0',one) as phone, type, stas, date 
FROM textcampaign.text_sent_status;

CREATE TABLE textcampaign._list1 engine = myisam
SELECT a.phone,  a.id,  a.userid,  a.total_redeem,  a.last_time_login,  a.text_campaign,  a.abtest_group,  a.status, b.stas
FROM textcampaign.retention_20150114_full_list_dont_delete a LEFT JOIN textcampaign._text_sent_status b on a.phone = b.phone;

# 發送佔比
SELECT abtest_group, status, count(phone) as c 
FROM textcampaign.retention_20150114_full_list_dont_delete
GROUP BY abtest_group, status;

# 1 sent    358
# 2 sent    392
# 3 sent    362
# 4 sent    363
# 5 sent    363
# 6 sent    364
# 7 hold    355
# 8 hold    317
# 9 hold    342
# 10    hold    351

SELECT status, count(phone) as c 
FROM textcampaign.retention_20150114_full_list_dont_delete
GROUP BY status;

# hold  1365
# sent  2202 (494失敗)

# 發送狀況檢察
SELECT status, stas, count(phone) as c 
FROM textcampaign._list1
GROUP BY status, stas;

CREATE TABLE textcampaign._list2 engine = myisam # 1708名
SELECT * 
FROM textcampaign._list1
WHERE status = 'sent'
AND stas is null;

# 回網站跳出訊息
CREATE TABLE textcampaign._coupon_window_pop_up engine = myisam
SELECT userid, outflowMember, (case when (outflowMember is not null) then 'see_pop' else '' end) as see
FROM plsport_playsport.showmessage
WHERE outflowmember is not null
ORDER BY outflowMember;

CREATE TABLE textcampaign._list3 engine = myisam
SELECT a.phone,  a.id,  a.userid,  a.total_redeem,  a.last_time_login,  a.text_campaign,  a.abtest_group,  a.status, a.stas, b.see
FROM textcampaign._list2 a LEFT JOIN textcampaign._coupon_window_pop_up b on a.userid = b.userid;

# 個人信箱獲得兌換券派送訊息
CREATE TABLE textcampaign._receive_coupon engine = myisam
SELECT tou, title, date, remarks 
FROM plsport_playsport.mailpcash_list
WHERE title LIKE '%恭喜獲得兌換券%';

CREATE TABLE textcampaign._list4 engine = myisam
SELECT a.phone,  a.id,  a.userid,  a.total_redeem,  a.last_time_login,  a.text_campaign,  a.abtest_group,  a.status, a.stas, a.see, b.remarks
FROM textcampaign._list3 a LEFT JOIN textcampaign._receive_coupon b on a.userid = b.tou;

CREATE TABLE textcampaign._spent engine = myisam
SELECT userid, sum(amount) as spent 
FROM plsport_playsport.pcash_log
WHERE payed = 1 AND type = 1
AND date between '2015-01-14 18:00:00' AND '2015-01-26 18:00:00'
GROUP BY userid;

# (1)有發送的
CREATE TABLE textcampaign._list5 engine = myisam
SELECT a.userid, a.text_campaign,  a.abtest_group,  a.status, a.stas, a.see, a.remarks, b.spent
FROM textcampaign._list4 a LEFT JOIN textcampaign._spent b on a.userid = b.userid;

# (2)沒有發送的
CREATE TABLE textcampaign._list5_hold engine = myisam
SELECT a.userid, a.text_campaign,  a.abtest_group, a.status, a.stas, b.spent
FROM textcampaign._list1 a LEFT JOIN textcampaign._spent b on a.userid = b.userid
WHERE a.status = 'hold';


# 星期二下午柔雅要求要補充的資訊
# 想要了解說，收到簡訊->回來領券->使用兌換券，的使用者的比例是多少，
# 若兌換券對他們而言是有吸引力的，那他們應該會依照上面的步驟進行，
# 請查詢，他們回來領完券後，一天內，是否有使用兌換券，而這個的比例是多少?
# http://pm.playsport.cc/index.php/tasksComments?tasksId=2269&projectId=11

# 匯入coupon_used_detail

# 在區間內使用抵用兌的記錄
CREATE TABLE textcampaign._coupon_used engine = myisam
SELECT userid, count(id) as coupon_used_count 
FROM plsport_playsport.coupon_used_detail
WHERE type = 1
AND date between '2015-01-14 18:00:00' AND '2015-01-26 18:00:00'
GROUP BY userid;

# 完成
SELECT a.userid, text_campaign, abtest_group, status, stas, see, remarks, spent, coupon_used_count
FROM textcampaign._list5 a LEFT JOIN textcampaign._coupon_used b on a.userid = b.userid;

# 社群會議後, 福利班補充要了解有多少人點擊了簡訊中的連結
# 文案:【限時獨享】立即登入玩運彩，送您金牌兌換券、免費看殺手預測《限量100份，先領先贏》 http://playsport.cc/ad/16
# http://www.playsport.cc/forum.php?ft=0&s=a&ft=0&utm_source=phone&utm_medium=text&utm_content=retention_a_20150114&utm_campaign=retention_a_20150114

CREATE TABLE textcampaign._who_click_link_in_text engine = myisam
SELECT userid, uri, time, platform_type, cookie_stamp, user_agent
FROM actionlog.action_201501
WHERE uri LIKE '%utm_content=retention_a_20150114%'
AND time between '2015-01-14 18:00:00' AND '2015-01-26 18:00:00';

SELECT userid, uri, cookie_stamp, date(min(time)) as time # 排除掉cookie重覆的記錄, 可以分析了
FROM textcampaign._who_click_link_in_text
GROUP BY userid, uri, cookie_stamp
ORDER BY time;



# ----------------------------------------------------------------------
# 流失客領取兌換券 (柔雅) 2015-02-12 後來過年後重新製作名單
#  TO EDDY:
# 我們預計在 2/12 下午6點，發送下一波簡訊，麻煩你協助撈取名單，
# 
# 條件不變，規則如下:
# 
# 1.約前一年半的時間內，曾經儲值過
# 2.已有三個月未登入、購買、儲值
# 3.依照儲值總金額排序，越高的優先發送
# 4.每次最多2000筆，匯出csv或txt(供yoyo8發送)
# 5.每一筆有效號碼，不要連續傳送，相隔一個月以上
# 
# ps.請另外提供一份有id的名單，給工程套入程式使用。
# 另外，請您試算，與上一波名單有重覆的人數有多少。
# 麻煩請於，2/11(三)提供。
# ----------------------------------------------------------------------

# 主名單: 近550天內曾經儲值過的人, 並有符合電話格式(10碼)
# update: 2015-04-29, 5月1日要發送
CREATE TABLE textcampaign._list1 engine = myisam
SELECT a.userid, a.phone, sum(a.price) as total_redeem
FROM (
    SELECT userid, phone, CREATEon, price 
    FROM plsport_playsport.order_data
    WHERE sellconfirm = 1 AND payway in (1,2,3,4,5,6,9,10)
    AND CREATEon between subdate(now(),570) AND now()) as a # 一年半內有儲值過
WHERE length(phone) = 10 AND substr(phone,1,2) = '09' AND phone regexp '^[[:digit:]]{10}$'
GROUP BY a.userid
ORDER BY a.userid;

# 拒收簡訊名單
CREATE TABLE textcampaign._who_dont_want_text engine = myisam
SELECT a.phone
FROM (
    SELECT userid, phone 
    FROM plsport_playsport.order_data
    WHERE receive_ad = 0) as a
GROUP BY a.phone;

# 近3個月內有登入的人(如果人數很多的話, 視情況可修改為近1個月)
CREATE TABLE textcampaign._recent_login engine = myisam
SELECT a.userid, count(a.userid) as c, (case when (a.userid is not null) then 'yes' end) as recent_login
FROM (
    SELECT * 
    FROM plsport_playsport.member_signin_log_archive
    WHERE signin_time between subdate(now(),91) AND now() # 設定為3個月
    ORDER BY signin_time) as a
GROUP BY a.userid;

# 每個人最後一次登入是何日
CREATE TABLE textcampaign._last_time_login engine = myisam
SELECT userid, date(max(signin_time)) as last_time_login
FROM plsport_playsport.member_signin_log_archive
GROUP BY userid;

# 主名單: 加入誰近3個月內有登入
CREATE TABLE textcampaign._list2 engine = myisam
SELECT a.userid, a.phone, a.total_redeem, b.recent_login
FROM textcampaign._list1 a LEFT JOIN textcampaign._recent_login b on a.userid = b.userid;

# 主名單: 排除掉拒收簡訊名單
CREATE TABLE textcampaign._list3 engine = myisam
SELECT a.userid, a.phone, total_redeem, a.recent_login
FROM textcampaign._list2 a LEFT JOIN textcampaign._who_dont_want_text b on a.phone = b.phone
WHERE b.phone is null;

# 主名單: 排除最近有登入的人
CREATE TABLE textcampaign._list4 engine = myisam
SELECT * 
FROM textcampaign._list3
WHERE recent_login is null; #不要留近3個月內有登入的人

        # 主名單: 完整版(加入使用者id, 和最近一次登入日期)
        create table plsport_playsport._fail_number engine = myisam
        SELECT concat('0',one) as phone, stas 
        FROM textcampaign.text_sent_status_0226
        where stas = '失敗';
        insert ignore into plsport_playsport._fail_number
        SELECT concat('0',one) as phone, stas 
        FROM textcampaign.text_sent_status
        where stas = '失敗';
        insert ignore into plsport_playsport._fail_number
        SELECT concat('0',phone) as phone, stas 
        FROM textcampaign.text_sent_status_0401
        where stas = '失敗';     

CREATE TABLE textcampaign._list5 engine = myisam
SELECT c.phone, d.id, c.userid, c.total_redeem, c.last_time_login, 
       (case when (d.id is not null) then 'retention_a_20150501' end) as text_campaign, ((d.id%10)+1) as abtest_group /*記得要指定campaign_name*/
FROM (
    SELECT a.userid, a.phone, a.total_redeem, b.last_time_login
    FROM textcampaign._list4 a LEFT JOIN textcampaign._last_time_login b on a.userid = b.userid) as c 
LEFT JOIN plsport_playsport.member as d on c.userid = d.userid; 

#排除掉號碼已經失效的的名單
CREATE TABLE textcampaign._list6 engine = myisam
SELECT a.phone, a.id, a.userid, a.total_redeem, a.last_time_login, a.text_campaign, a.abtest_group
FROM textcampaign._list5 a LEFT JOIN plsport_playsport._fail_number b on a.phone = b.phone
WHERE b.stas is null;

CREATE TABLE textcampaign._list7 engine = myisam
SELECT a.phone, a.id, a.userid, a.total_redeem, a.last_time_login, a.text_campaign, a.abtest_group
FROM textcampaign._list6 a left join textcampaign.retention_c_20150501_full_list_dont_delete b on a.phone = b.phone
where b.text_campaign is null;

#發送60%的人, 40%的人保留
CREATE TABLE textcampaign._list8 engine = myisam
SELECT phone, id, userid, total_redeem, last_time_login, text_campaign, abtest_group, 
       (case when (abtest_group<7) then 'sent' else 'hold' end) as status /*60:40 發送/不發*/
FROM textcampaign._list7;

CREATE TABLE textcampaign.retention_a_20150501_full_list_dont_delete engine = myisam
SELECT * FROM textcampaign._list8; 

        # 給yoyo8簡訊發送
        SELECT 'phone', '使用者編號id', '簡訊行銷' UNION (
        SELECT phone, id, text_campaign
        INTO outfile 'C:/Users/1-7_ASUS/Desktop/retention_a_20150501_for_yoyo8.csv'
        CHARACTER SET big5 fields terminated by ',' enclosed by '' lines terminated by '\r\n' 
        FROM textcampaign._list8
        WHERE status = 'sent'); # 只撈出有要發送的
        # 一定要設定為big編碼, yoyo8規定的

        # 給工程部匯入兌換券發送系統
        SELECT userid
        INTO outfile 'C:/Users/1-7_ASUS/Desktop/retention_a_20150501_for_software_team.csv'
        fields terminated by ',' enclosed by '' lines terminated by '\r\n' 
        FROM textcampaign._list8
        WHERE status = 'sent'; # 只撈出有要發送的
# 以上在2015-04-29有更新(for5月1日的名單) ---------------------------------------------------------- 
        
  
# 另外，請您試算，與上一波名單有重覆的人數有多少。
        CREATE TABLE textcampaign._check engine = myisam
        SELECT a.phone, a.userid, a.text_campaign, b.text_campaign as last_time
        FROM textcampaign.retention_20150226_full_list_dont_delete a LEFT JOIN textcampaign.retention_20150114_full_list_dont_delete b on a.phone = b.phone;

        SELECT last_time, count(phone)  # 2861
        FROM textcampaign._check
        GROUP BY last_time;

        SELECT count(phone) # 3758
        FROM textcampaign._check;

# 以下是分析的部分 (2015-03-03)-再次執行分析 (2015-03-10)----------------------

# 簡訊發送的成功率
SELECT stas, count(one) as c 
FROM textcampaign.text_sent_status_0226
GROUP BY stas;
# 失敗    123
# 成功    1810 / 1933 = 0.936

CREATE TABLE textcampaign._who_receive_text engine = myisam
SELECT concat('0',one) as phone, stas, date 
FROM textcampaign.text_sent_status_0226;

CREATE TABLE textcampaign._full_list engine = myisam
SELECT a.phone, a.id, a.userid, a.total_redeem, a.last_time_login, a.text_campaign, a.abtest_group, a.status, b.stas, concat(a.status,'_',b.stas) as s
FROM textcampaign.retention_20150226_full_list_dont_delete a LEFT JOIN textcampaign._who_receive_text b on a.phone = b.phone;

# 檢查
SELECT s, count(phone) 
FROM textcampaign._full_list_1
GROUP BY s;

CREATE TABLE textcampaign._full_list_1 engine = myisam
SELECT *
FROM textcampaign._full_list
WHERE s is null OR s in ('sent_成功');


# 回網站跳出訊息
CREATE TABLE textcampaign._coupon_window_pop_up engine = myisam
SELECT userid, outflowMember, (case when (outflowMember is not null) then 'see_pop' else '' end) as see
FROM plsport_playsport.showmessage
WHERE outflowmember is not null
AND outflowMember between '2015-02-26 18:01:13' AND '2015-02-28 21:59:13'
ORDER BY outflowMember;

CREATE TABLE textcampaign._full_list_2 engine = myisam
SELECT a.phone, a.id, a.userid, a.total_redeem, a.last_time_login, a.text_campaign, a.abtest_group, a.status, a.stas, b.see  
FROM textcampaign._full_list_1 a LEFT JOIN textcampaign._coupon_window_pop_up b on a.userid = b.userid;


# 個人信箱獲得兌換券派送訊息( mailpcash_list蠻大的, 要捉很久)
CREATE TABLE textcampaign._receive_coupon engine = myisam
SELECT tou, title, date, remarks 
FROM plsport_playsport.mailpcash_list
WHERE title LIKE '%恭喜獲得兌換券%'
AND date between '2015-02-26 18:01:20' AND '2015-02-28 21:47:01';

CREATE TABLE textcampaign._full_list_3 engine = myisam
SELECT a.phone, a.id, a.userid, a.total_redeem, a.last_time_login, a.text_campaign, a.abtest_group, a.status, a.stas, a.see, b.title as message
FROM textcampaign._full_list_2 a LEFT JOIN textcampaign._receive_coupon b on a.userid = b.tou;

CREATE TABLE textcampaign._spent engine = myisam
SELECT userid, sum(amount) as spent
FROM plsport_playsport.pcash_log
WHERE payed = 1 AND type = 1
AND date between '2015-02-26 18:01:13' AND now()
GROUP BY userid;

CREATE TABLE textcampaign._full_list_4 engine = myisam
SELECT a.phone, a.id, a.userid, a.total_redeem, a.last_time_login, a.text_campaign, a.abtest_group, a.status, a.stas, a.see, a.message, b.spent
FROM textcampaign._full_list_3 a LEFT JOIN textcampaign._spent b on a.userid = b.userid;

        SELECT * FROM textcampaign._full_list_4
        WHERE status = 'sent'
        AND stas = '成功'
        AND see = 'see_pop'
        AND message is not null
        AND spent is not null;

        SELECT status, stas, count(userid) as user_count 
        FROM textcampaign._full_list_4
        group by status, stas;

        SELECT status, sum(spent) as revenue, count(userid) as user_count
        FROM textcampaign._full_list_4
        WHERE spent is not null
        group by status;
        
        SELECT status, count(phone) 
        FROM textcampaign._full_list_4
        GROUP BY status;
        
# 計算在期間內, 有使用抵用券的記錄
CREATE TABLE textcampaign._coupon_used engine = myisam
SELECT userid, count(id) as coupon_used_count 
FROM plsport_playsport.coupon_used_detail
WHERE type = 1
AND date between '2015-02-26 18:01:13' AND now()
GROUP BY userid;        
        
CREATE TABLE textcampaign._full_list_5 engine = myisam
SELECT a.userid, a.status, a.stas, a.see, a.message, a.spent, b.coupon_used_count
FROM textcampaign._full_list_4 a left join textcampaign._coupon_used b on a.userid = b.userid;

SELECT * FROM textcampaign._full_list_5
where status = 'sent'
and coupon_used_count is not null;


SELECT * FROM actionlog.action_201502
WHERE urik LIKE '%retention_a_20150226%';

CREATE TABLE textcampaign._who_click_link_in_text engine = myisam
SELECT userid, uri, time, platform_type, cookie_stamp, user_agent
FROM actionlog.action_201502
WHERE uri LIKE '%utm_content=retention_a_20150226%'
AND time between '2015-02-26 18:00:00' AND '2015-02-28 23:59:59';


# 2015-03-16 (柔雅)
# http://pm.playsport.cc/index.php/tasksComments?tasksId=2269&projectId=11
#  *開會後，原有發送兌換券方式，確認有效，
# 確定每三個月發送一次，下次發送為5月份。
# 
# *另外新增一個撈取流失客名單的規則，
# 主要是針對，近期增加的流失客，在他即將離開網站時，再拉住他一次。
# 名單撈取規則為:
#  
#      舉例:1月份有購買預測(幣/券)、2月份完全沒購買預測(幣/券)、3月份發送簡訊。
# 
# 發送方式一樣: 給予兌換券。
# 發送週期:每月一次。
# 先用這個規則去撈取名單、查看數量，
# eddy預計3/18提供初步名單。
# - 若使用者收到兩次簡訊，列為永久流失，不再發送簡訊。
# - 以上兩種方式，需要abtesting做為檢驗。
#     任務狀態: 進行中

# 下面這份名單是針對短期的流失客 2015-03-30
# 匯入 (1)pcash_log (2)coupon_used_detail (3)order_data

# update 2015-04-29: 5月1日要發送一批
create table plsport_playsport._who_spent_before_31_days engine = myisam /*誰在31天之前有購買預測*/
select a.userid, sum(a.amount) as spent
from ( 
    SELECT userid, amount, date 
    FROM plsport_playsport.pcash_log
    where payed = 1 and type = 1
    and date between subdate(now(),61) and subdate(now(),31)) as a
group by a.userid;

create table plsport_playsport._who_use_conpon_before_31_days engine = myisam /*誰在31天之前有用過抵用券*/
select a.userid, count(userid) as coupon
from (
    SELECT userid, date
    FROM plsport_playsport.coupon_used_detail
    where type = 1 and coupon_type = 1
    and date between subdate(now(),61) and subdate(now(),31)) as a
group by a.userid;

        ALTER TABLE plsport_playsport._who_spent_before_31_days ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._who_use_conpon_before_31_days ADD INDEX (`userid`);

        create table plsport_playsport._list_before_31_days engine = myisam /*曾在31天之前有購買過預測或用過抵用券的人*/
        select c.userid, c.spent, d.coupon
        from (
            SELECT a.userid, b.spent
            FROM plsport_playsport.member a left join plsport_playsport._who_spent_before_31_days b on a.userid = b.userid) as c 
            left join plsport_playsport._who_use_conpon_before_31_days as d on c.userid = d.userid
        where c.spent is not null or d.coupon is not null;

create table plsport_playsport._who_spent_in_31_days engine = myisam/*誰在31天之內有購買過預測*/
select a.userid, sum(a.amount) as spent
from ( 
    SELECT userid, amount, date 
    FROM plsport_playsport.pcash_log
    where payed = 1 and type = 1
    and date between subdate(now(),31) and now()) as a
group by a.userid;

create table plsport_playsport._who_use_coupon_in_31_days engine = myisam/*誰在31天之內有用過抵用券*/
select a.userid, count(userid) as coupon
from (
    SELECT userid, date
    FROM plsport_playsport.coupon_used_detail
    where type = 1 and coupon_type = 1
    and date between subdate(now(),31) and now()) as a
group by a.userid;

        ALTER TABLE plsport_playsport._who_spent_in_31_days ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._who_use_coupon_in_31_days ADD INDEX (`userid`);

        create table plsport_playsport._list_all engine = myisam /*曾在31天之內有購買過預測或用過抵用券的人*/
        select c.userid, c.spent, c.coupon, c.spent1, d.coupon as coupon1
        from (
            SELECT a.userid, a.spent, a.coupon, b.spent as spent1
            FROM plsport_playsport._list_before_31_days a left join plsport_playsport._who_spent_in_31_days b on a.userid = b.userid) as c 
            left join plsport_playsport._who_use_coupon_in_31_days as d on c.userid = d.userid
        where c.spent is not null or d.coupon is not null;

#產生主名單:誰在31天之前有消費或用券, 但在31天之內完全沒有消費或用券
create table plsport_playsport._list_all_1 engine = myisam
SELECT * FROM plsport_playsport._list_all
where spent1 is null and coupon1 is null;

#撈全站手機號碼
CREATE TABLE plsport_playsport._phone_number engine = myisam
SELECT a.userid, a.phone, sum(a.price) as total_redeem
FROM (
    SELECT userid, phone, CREATEon, price 
    FROM plsport_playsport.order_data
    WHERE sellconfirm = 1 AND payway in (1,2,3,4,5,6,9,10)
    AND CREATEON between subdate(now(),570) AND now()) as a # 一年半內有儲值過
WHERE length(phone) = 10 AND substr(phone,1,2) = '09' AND phone regexp '^[[:digit:]]{10}$'
GROUP BY a.userid
ORDER BY a.userid;

#誰不要收簡訊
CREATE TABLE plsport_playsport._who_dont_want_text engine = myisam
SELECT a.phone
FROM (
    SELECT userid, phone 
    FROM plsport_playsport.order_data
    WHERE receive_ad = 0) as a
GROUP BY a.phone;

create table plsport_playsport._list_all_2 engine = myisam
SELECT a.userid, b.phone, a.spent, a.coupon, a.spent1, a.coupon1 
FROM plsport_playsport._list_all_1 a left join plsport_playsport._phone_number b on a.userid = b.userid;

create table plsport_playsport._list_all_3 engine = myisam
SELECT a.userid, a.phone, a.spent, a.coupon, a.spent1, a.coupon1 
FROM plsport_playsport._list_all_2 a left join plsport_playsport._who_dont_want_text b on a.phone = b.phone
where b.phone is null;

        # 產生曾發送簡訊, 但號碼已經失效的的名單
        create table plsport_playsport._fail_number engine = myisam
        SELECT concat('0',one) as phone, stas 
        FROM textcampaign.text_sent_status_0226
        where stas = '失敗';
        insert ignore into plsport_playsport._fail_number
        SELECT concat('0',one) as phone, stas 
        FROM textcampaign.text_sent_status
        where stas = '失敗';
        insert ignore into plsport_playsport._fail_number
        SELECT concat('0',phone) as phone, stas 
        FROM textcampaign.text_sent_status_0401
        where stas = '失敗';      
        
        create table plsport_playsport._fail_number_1 engine = myisam
        SELECT phone, stas 
        FROM plsport_playsport._fail_number
        group by phone, stas;

#排除掉號碼已經失效的的名單
create table plsport_playsport._list_all_4 engine = myisam
SELECT  a.userid, a.phone, a.spent, a.coupon, a.spent1, a.coupon1 
FROM plsport_playsport._list_all_3 a left join plsport_playsport._fail_number_1 b on a.phone = b.phone
where b.phone is null;

#排除掉沒有號碼的人
create table plsport_playsport._list_all_5 engine = myisam
SELECT * FROM plsport_playsport._list_all_4
where phone is not null;

#排除掉上回有收到簡訊的人
create table plsport_playsport._list_all_6 engine = myisam
SELECT a.userid, a.phone, a.spent, a.coupon, a.spent1, a.coupon1
FROM plsport_playsport._list_all_5 a left join textcampaign.retention_c_20150401_full_list_dont_delete b on a.userid = b.userid
where b.text_campaign is null;

#發送60%的人, 40%的人保留
create table plsport_playsport._list_all_7 engine = myisam
SELECT (b.id%10)+1 as g, (case when ((b.id%10)+1<7) then 'sent' else 'hold' end) as abtest, b.id, a.userid, a.phone, a.spent, a.coupon, a.spent1, a.coupon1, # 60%要發送
       (case when (a.userid is not null) then 'retention_c_20150501' else '' end) as text_campaign
FROM plsport_playsport._list_all_6 a left join plsport_playsport.member b on a.userid = b.userid;

create table textcampaign.retention_c_20150501_full_list_dont_delete engine = myisam
SELECT * FROM plsport_playsport._list_all_7;

        # 給yoyo8簡訊發送
        SELECT 'phone', '使用者編號id', '簡訊行銷' UNION (
        SELECT phone, id, text_campaign
        INTO outfile 'C:/Users/1-7_ASUS/Desktop/retention_c_20150501_for_yoyo8.csv'
        CHARACTER SET big5 fields terminated by ',' enclosed by '' lines terminated by '\r\n' 
        FROM textcampaign.retention_c_20150501_full_list_dont_delete
        WHERE abtest = 'sent'); # 只撈出有要發送的
        # 一定要設定為big編碼, yoyo8規定的

        # 給工程部匯入兌換券發送系統
        SELECT userid
        INTO outfile 'C:/Users/1-7_ASUS/Desktop/retention_c_20150501_for_software_team.csv'
        fields terminated by ',' enclosed by '' lines terminated by '\r\n' 
        FROM textcampaign.retention_c_20150501_full_list_dont_delete
        WHERE abtest = 'sent'; # 只撈出有要發送的
# 針對近期流失客的名單產生至此-------------------------------------------------------------------


# 以下是分析的部分 (2015-04-14)

# 簡訊發送的成功率
SELECT stas, count(phone) as c 
FROM textcampaign.text_sent_status_0401
GROUP BY stas;
# 失敗    48
# 成功    288 / 336 = 0.857

CREATE TABLE textcampaign._who_receive_text engine = myisam
SELECT concat('0',phone) as phone, stas, date 
FROM textcampaign.text_sent_status_0401;

CREATE TABLE textcampaign._full_list engine = myisam
SELECT a.phone, a.id, a.userid, a.text_campaign, a.abtest, b.stas, concat(a.abtest, '_', b.stas) as s
FROM textcampaign.retention_c_20150401_full_list_dont_delete a LEFT JOIN textcampaign._who_receive_text b on a.phone = b.phone;

# 檢查
SELECT s, count(phone) 
FROM textcampaign._full_list
GROUP BY s;

# null   	220
# sent_失敗	48
# sent_成功 290

CREATE TABLE textcampaign._full_list_1 engine = myisam
SELECT *
FROM textcampaign._full_list
WHERE s is null OR s in ('sent_成功');


# 回網站跳出訊息
CREATE TABLE textcampaign._coupon_window_pop_up engine = myisam
SELECT userid, outflowMember, (case when (outflowMember is not null) then 'see_pop' else '' end) as see
FROM plsport_playsport.showMessage
WHERE outflowmember is not null
AND outflowMember between '2015-04-01 18:01:13' AND '2015-04-03 23:59:59'
ORDER BY outflowMember;

CREATE TABLE textcampaign._full_list_2 engine = myisam
SELECT a.phone, a.id, a.userid, a.text_campaign, a.abtest, a.stas, b.see  
FROM textcampaign._full_list_1 a LEFT JOIN textcampaign._coupon_window_pop_up b on a.userid = b.userid;

# 個人信箱獲得兌換券派送訊息( mailpcash_list蠻大的, 要捉很久)
CREATE TABLE textcampaign._receive_coupon engine = myisam
SELECT tou, title, date, remarks 
FROM plsport_playsport.mailpcash_list
WHERE title LIKE '%恭喜獲得兌換券%'
AND date between '2015-04-01 18:00:00' AND '2015-04-03 23:59:59';

CREATE TABLE textcampaign._full_list_3 engine = myisam
SELECT a.phone, a.id, a.userid, a.text_campaign, a.abtest, a.stas, a.see, b.title as message
FROM textcampaign._full_list_2 a LEFT JOIN textcampaign._receive_coupon b on a.userid = b.tou;

CREATE TABLE textcampaign._spent engine = myisam
SELECT userid, sum(amount) as spent
FROM plsport_playsport.pcash_log
WHERE payed = 1 AND type = 1
AND date between '2015-04-01 18:00:00' AND now()
GROUP BY userid;

CREATE TABLE textcampaign._full_list_4 engine = myisam
SELECT a.phone, a.id, a.userid, a.text_campaign, a.abtest, a.stas, a.see, a.message, b.spent
FROM textcampaign._full_list_3 a LEFT JOIN textcampaign._spent b on a.userid = b.userid;

SELECT * FROM textcampaign._full_list_4;

        SELECT * FROM textcampaign._full_list_4
        WHERE abtest = 'sent'
        AND stas = '成功'
        AND see = 'see_pop'
        AND message is not null
        AND spent is not null;

        SELECT abtest, stas, count(userid) as user_count 
        FROM textcampaign._full_list_4
        group by abtest, stas;
        
#         hold		    220
#         sent	成功 	290

        SELECT abtest, sum(spent) as revenue, count(userid) as user_count
        FROM textcampaign._full_list_4
        WHERE spent is not null
        group by abtest;
        
        SELECT abtest, count(phone) 
        FROM textcampaign._full_list_4
        GROUP BY abtest;
        
# 計算在期間內, 有使用抵用券的記錄
CREATE TABLE textcampaign._coupon_used engine = myisam
SELECT userid, count(id) as coupon_used_count 
FROM plsport_playsport.coupon_used_detail
WHERE type = 1
AND date between '2015-04-01 18:00:00' AND now()
GROUP BY userid;        
        
CREATE TABLE textcampaign._full_list_5 engine = myisam
SELECT a.userid, a.abtest, a.stas, a.see, a.message, a.spent, b.coupon_used_count
FROM textcampaign._full_list_4 a left join textcampaign._coupon_used b on a.userid = b.userid;

SELECT * FROM textcampaign._full_list_5
where abtest = 'sent'
and coupon_used_count is not null;

# 點擊補充
SELECT * FROM actionlog.action_201502
WHERE uri LIKE '%retention_a_20150226%';

CREATE TABLE textcampaign._who_click_link_in_text engine = myisam
SELECT userid, uri, time, platform_type, cookie_stamp, user_agent
FROM actionlog.action_201504
WHERE uri LIKE '%utm_content=retention_c_20150401%'
AND time between '2015-04-01 18:00:00' AND '2015-04-03 23:59:59';

# 檢查2組儲值噱幣的狀況
create table textcampaign._who_have_redeem engine = myisam
SELECT userid, sum(amount) as redeem, count(amount) as redeem_count 
FROM plsport_playsport.pcash_log
where payed = 1 and type in (3,4)
and date between '2015-04-01 18:00:00' AND now() 
group by userid;

create table textcampaign._full_list_6 engine = myisam
SELECT a.userid, a.abtest, a.stas, a.see, a.message, a.spent, a.coupon_used_count, b.redeem, b.redeem_count 
FROM textcampaign._full_list_5 a left join textcampaign._who_have_redeem b on a.userid = b.userid;

SELECT count(userid) as redeem_user_count, sum(redeem) as total_redeem_count 
FROM textcampaign._full_list_6
where abtest = 'sent' and stas = '成功' and spent is not null and redeem is not null;

SELECT count(userid) as redeem_user_count, sum(redeem) as total_redeem_count 
FROM textcampaign._full_list_6
where abtest = 'hold' and spent is not null and redeem is not null;


SELECT *
FROM textcampaign._full_list_6
where abtest = 'hold' and spent is not null and redeem is not null;


# 2015-05-25 分析的部分
# (1)
# 2015/05/01  18:00發送
# 發送手段: 針對近期流失客，領取兌換券
# 文案:【【限時回饋】玩運彩贏錢預測，馬上登入、領券免費看！贏錢好容易！《限時兩天，先領先贏》http://playsport.cc/ad/19
# 程式執行時間:2天(05/01 18:00 - 05/03 22:00)
# 筆數:1800
# 
# (2)
# 2015/05/01  18:00發送
# 發送手段: 針對近期流失客，領取兌換券
# 文案:【限時回饋】玩運彩贏錢預測，馬上登入、領券免費看！贏錢好容易！《限時兩天，先領先贏》 http://playsport.cc/ad/20
# 程式執行時間:2天(05/01 18:00 - 05/03 22:00)
# 筆數:328


# 先匯入yoyo8的簡訊發送狀態記錄
create table textcampaign.text_sent_status_0501_a engine = myisam
SELECT concat(0,phone) as phone, type, stas, date, time, text_contect, campaign 
FROM textcampaign.text_sent_status_0501 where campaign = 'a';

create table textcampaign.text_sent_status_0501_c engine = myisam
SELECT concat(0,phone) as phone, type, stas, date, time, text_contect, campaign 
FROM textcampaign.text_sent_status_0501 where campaign = 'c';

# 主名單
create table textcampaign.text_sent_status_0501_a_1 engine = myisam
SELECT a.phone, a.userid, a.text_campaign, a.status, b.stas
FROM textcampaign.retention_a_20150501_full_list_dont_delete a left join textcampaign.text_sent_status_0501_a b on a.phone = b.phone;

create table textcampaign.text_sent_status_0501_c_1 engine = myisam
SELECT a.phone, a.userid, a.text_campaign, a.abtest as status, b.stas
FROM textcampaign.retention_c_20150501_full_list_dont_delete a left join textcampaign.text_sent_status_0501_c b on a.phone = b.phone;

# 回網站跳出訊息
CREATE TABLE textcampaign._coupon_window_pop_up engine = myisam
SELECT userid, outflowMember, (case when (outflowMember is not null) then 'see_pop' else '' end) as see
FROM plsport_playsport.showMessage
WHERE outflowmember is not null
AND outflowMember between '2015-05-01 18:00:00' AND '2015-05-03 22:00:00'
ORDER BY outflowMember;

# 有誰回網站看到領取抵用券提示視窗
create table textcampaign.text_sent_status_0501_a_2 engine = myisam
SELECT a.phone, a.userid, a.text_campaign, a.status, a.stas, b.see
FROM textcampaign.text_sent_status_0501_a_1 a left join textcampaign._coupon_window_pop_up b on a.userid = b.userid;

create table textcampaign.text_sent_status_0501_c_2 engine = myisam
SELECT a.phone, a.userid, a.text_campaign, a.status, a.stas, b.see
FROM textcampaign.text_sent_status_0501_c_1 a left join textcampaign._coupon_window_pop_up b on a.userid = b.userid;


# 個人信箱獲得兌換券派送訊息( mailpcash_list蠻大的, 要捉很久)
CREATE TABLE textcampaign._receive_coupon engine = myisam
SELECT tou, title, date, remarks 
FROM plsport_playsport.mailpcash_list
WHERE title LIKE '%恭喜獲得兌換券%'
AND date between '2015-05-01 18:00:00' AND '2015-05-03 22:00:00';

# 有誰實際領取到抵用券
create table textcampaign.text_sent_status_0501_a_3 engine = myisam
SELECT a.phone, a.userid, a.text_campaign, a.status, a.stas, a.see, b.title 
FROM textcampaign.text_sent_status_0501_a_2 a left join textcampaign._receive_coupon b on a.userid = b.tou;

create table textcampaign.text_sent_status_0501_c_3 engine = myisam
SELECT a.phone, a.userid, a.text_campaign, a.status, a.stas, a.see, b.title 
FROM textcampaign.text_sent_status_0501_c_2 a left join textcampaign._receive_coupon b on a.userid = b.tou;


CREATE TABLE textcampaign._spent engine = myisam
SELECT userid, sum(amount) as spent
FROM plsport_playsport.pcash_log
WHERE payed = 1 AND type = 1
AND date between '2015-05-01 18:00:00' AND '2015-06-26 23:59:59' # edited:原本是'2015-05-15 23:59:59'
GROUP BY userid;

# 加上期間內消費多少金額
create table textcampaign.text_sent_status_0501_a_4 engine = myisam
SELECT a.phone, a.userid, a.text_campaign, a.status, a.stas, a.see, a.title, b.spent
FROM textcampaign.text_sent_status_0501_a_3 a left join textcampaign._spent b on a.userid = b.userid;

create table textcampaign.text_sent_status_0501_c_4 engine = myisam
SELECT a.phone, a.userid, a.text_campaign, a.status, a.stas, a.see, a.title, b.spent
FROM textcampaign.text_sent_status_0501_c_3 a left join textcampaign._spent b on a.userid = b.userid;



# a/b testing 計算機
# A>B
# C>D
#長期
#A
SELECT * FROM textcampaign.text_sent_status_0501_a_4
where status = 'sent' and stas = '成功';
#B
SELECT * FROM textcampaign.text_sent_status_0501_a_4
where status = 'sent' and stas = '成功' and spent is not null;
#C
SELECT * FROM textcampaign.text_sent_status_0501_a_4
where status = 'hold' and stas is null;
#D
SELECT * FROM textcampaign.text_sent_status_0501_a_4
where status = 'hold' and stas is null and spent is not null;

#短期
#A
SELECT * FROM textcampaign.text_sent_status_0501_c_4
where status = 'sent' and stas = '成功';
#B
SELECT * FROM textcampaign.text_sent_status_0501_c_4
where status = 'sent' and stas = '成功' and spent is not null;
#C
SELECT * FROM textcampaign.text_sent_status_0501_c_4
where status = 'hold' and stas is null;
#D
SELECT * FROM textcampaign.text_sent_status_0501_c_4
where status = 'hold' and stas is null and spent is not null;

# 誰有回來網站
SELECT * FROM textcampaign.text_sent_status_0501_a_4
where see is not null;
SELECT * FROM textcampaign.text_sent_status_0501_c_4
where see is not null;

# 誰有回來網站
SELECT * FROM textcampaign.text_sent_status_0501_a_4
where title is not null;
SELECT * FROM textcampaign.text_sent_status_0501_c_4
where title is not null;


# 計算在期間內, 有使用抵用券的記錄
CREATE TABLE textcampaign._coupon_used engine = myisam
SELECT userid, count(id) as coupon_used_count 
FROM plsport_playsport.coupon_used_detail
WHERE type = 1
AND date between '2015-05-01 18:00:00' AND '2015-06-26 23:59:59' # edited:原本是'2015-05-15 23:59:59'
GROUP BY userid; 


create table textcampaign.text_sent_status_0501_a_5 engine = myisam
SELECT a.phone, a.userid, a.text_campaign, a.status, a.stas, a.see, a.title, a.spent, b.coupon_used_count 
FROM textcampaign.text_sent_status_0501_a_4 a left join textcampaign._coupon_used b on a.userid = b.userid;

create table textcampaign.text_sent_status_0501_c_5 engine = myisam
SELECT a.phone, a.userid, a.text_campaign, a.status, a.stas, a.see, a.title, a.spent, b.coupon_used_count 
FROM textcampaign.text_sent_status_0501_c_4 a left join textcampaign._coupon_used b on a.userid = b.userid;

# 有誰在期間內用過抵用券
SELECT * FROM textcampaign.text_sent_status_0501_a_5
where status = 'sent' and stas = '成功' and see is not null and title is not null 
and coupon_used_count is not null;

SELECT * FROM textcampaign.text_sent_status_0501_c_5
where status = 'sent' and stas = '成功' and see is not null and title is not null 
and coupon_used_count is not null;


# 有誰點過簡訊的連結
create table textcampaign._who_click_text_message engine = myisam 
SELECT userid, uri, time, platform_type
FROM actionlog.action_201505
where uri like '%retention%'
and time between '2015-05-01 18:00:00' and '2015-05-03 22:59:59';

# 點過簡訊的連結次數
select a.cam, count(a.uri) as c
from (
    SELECT userid, uri, time, platform_type, substr(uri, locate('utm_campaign=',uri)+23,1) as cam
    FROM textcampaign._who_click_text_message) as a
group by a.cam;

create table textcampaign._who_have_redeem engine = myisam
SELECT userid, sum(amount) as redeem, count(amount) as redeem_count 
FROM plsport_playsport.pcash_log
where payed = 1 and type in (3,4)
and date between '2015-05-01 18:00:00' AND '2015-06-26 23:59:59' # edited:原本是'2015-05-15 23:59:59'
group by userid;

create table textcampaign.text_sent_status_0501_a_6 engine = myisam
SELECT a.phone, a.userid, a.text_campaign, a.status, a.stas, a.see, a.title, a.spent, a.coupon_used_count, b.redeem, b.redeem_count 
FROM textcampaign.text_sent_status_0501_a_5 a left join textcampaign._who_have_redeem b on a.userid = b.userid;

create table textcampaign.text_sent_status_0501_c_6 engine = myisam
SELECT a.phone, a.userid, a.text_campaign, a.status, a.stas, a.see, a.title, a.spent, a.coupon_used_count, b.redeem, b.redeem_count 
FROM textcampaign.text_sent_status_0501_c_5 a left join textcampaign._who_have_redeem b on a.userid = b.userid;


SELECT * FROM textcampaign.text_sent_status_0501_a_6
where status = 'sent' and stas = '成功' and spent is not null;

SELECT * FROM textcampaign.text_sent_status_0501_a_6
where status = 'hold' and stas is null and spent is not null;

SELECT count(userid) as redeem_user_count, sum(redeem) as total_redeem_count 
FROM textcampaign.text_sent_status_0501_c_6
where status = 'sent' and stas = '成功' and spent is not null and redeem is not null;

SELECT count(userid) as redeem_user_count, sum(redeem) as total_redeem_count 
FROM textcampaign.text_sent_status_0501_c_6
where status = 'hold' and stas is null and spent is not null and redeem is not null;



# =================================================================================================
# TOeddy: 2015-06-04
# http://pm.playsport.cc/index.php/tasksComments?tasksId=2269&projectId=11
# 預計下週五(6/5)下午18:00要發送第三次的近期流失客簡訊，
# 麻煩請於6/4提供名單，以利工程匯入，感謝!
# 
#     任務狀態: 進行中
# =================================================================================================

# 下面這份名單是針對短期的流失客 2015-06-04
# 匯入 (1)pcash_log (2)coupon_used_detail (3)order_data

# update 2015-06-04: 6月5日要發送一批

create table plsport_playsport._who_spent_before_31_days engine = myisam /*誰在31天之前有購買預測*/
select a.userid, sum(a.amount) as spent
from ( 
    SELECT userid, amount, date 
    FROM plsport_playsport.pcash_log
    where payed = 1 and type = 1
    and date between subdate(now(),61) and subdate(now(),31)) as a
group by a.userid;

create table plsport_playsport._who_use_conpon_before_31_days engine = myisam /*誰在31天之前有用過抵用券*/
select a.userid, count(userid) as coupon
from (
    SELECT userid, date
    FROM plsport_playsport.coupon_used_detail
    where type = 1 and coupon_type = 1
    and date between subdate(now(),61) and subdate(now(),31)) as a
group by a.userid;

        ALTER TABLE plsport_playsport._who_spent_before_31_days ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._who_use_conpon_before_31_days ADD INDEX (`userid`);

        create table plsport_playsport._list_before_31_days engine = myisam /*曾在31天之前有購買過預測或用過抵用券的人*/
        select c.userid, c.spent, d.coupon
        from (
            SELECT a.userid, b.spent
            FROM plsport_playsport.member a left join plsport_playsport._who_spent_before_31_days b on a.userid = b.userid) as c 
            left join plsport_playsport._who_use_conpon_before_31_days as d on c.userid = d.userid
        where c.spent is not null or d.coupon is not null;


create table plsport_playsport._who_spent_in_31_days engine = myisam/*誰在31天之內有購買過預測*/
select a.userid, sum(a.amount) as spent
from ( 
    SELECT userid, amount, date 
    FROM plsport_playsport.pcash_log
    where payed = 1 and type = 1
    and date between subdate(now(),31) and now()) as a
group by a.userid;

create table plsport_playsport._who_use_coupon_in_31_days engine = myisam/*誰在31天之內有用過抵用券*/
select a.userid, count(userid) as coupon
from (
    SELECT userid, date
    FROM plsport_playsport.coupon_used_detail
    where type = 1 and coupon_type = 1
    and date between subdate(now(),31) and now()) as a
group by a.userid;

        ALTER TABLE plsport_playsport._who_spent_in_31_days ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._who_use_coupon_in_31_days ADD INDEX (`userid`);

        create table plsport_playsport._list_all engine = myisam /*曾在31天之內有購買過預測或用過抵用券的人*/
        select c.userid, c.spent, c.coupon, c.spent1, d.coupon as coupon1
        from (
            SELECT a.userid, a.spent, a.coupon, b.spent as spent1
            FROM plsport_playsport._list_before_31_days a left join plsport_playsport._who_spent_in_31_days b on a.userid = b.userid) as c 
            left join plsport_playsport._who_use_coupon_in_31_days as d on c.userid = d.userid
        where c.spent is not null or d.coupon is not null;

#產生主名單:誰在31天之前有消費或用券, 但在31天之內完全沒有消費或用券
create table plsport_playsport._list_all_1 engine = myisam
SELECT * FROM plsport_playsport._list_all
where spent1 is null and coupon1 is null;

#撈全站手機號碼
CREATE TABLE plsport_playsport._phone_number engine = myisam
SELECT a.userid, a.phone, sum(a.price) as total_redeem
FROM (
    SELECT userid, phone, CREATEon, price 
    FROM plsport_playsport.order_data
    WHERE sellconfirm = 1 AND payway in (1,2,3,4,5,6,9,10)
    AND CREATEON between subdate(now(),570) AND now()) as a # 一年半內有儲值過
WHERE length(phone) = 10 AND substr(phone,1,2) = '09' AND phone regexp '^[[:digit:]]{10}$'
GROUP BY a.userid
ORDER BY a.userid;

#誰不要收簡訊
CREATE TABLE plsport_playsport._who_dont_want_text engine = myisam
SELECT a.phone
FROM (
    SELECT userid, phone 
    FROM plsport_playsport.order_data
    WHERE receive_ad = 0) as a
GROUP BY a.phone;


create table plsport_playsport._list_all_2 engine = myisam
SELECT a.userid, b.phone, a.spent, a.coupon, a.spent1, a.coupon1 
FROM plsport_playsport._list_all_1 a left join plsport_playsport._phone_number b on a.userid = b.userid;

create table plsport_playsport._list_all_3 engine = myisam
SELECT a.userid, a.phone, a.spent, a.coupon, a.spent1, a.coupon1 
FROM plsport_playsport._list_all_2 a left join plsport_playsport._who_dont_want_text b on a.phone = b.phone
where b.phone is null;

        # 產生曾發送簡訊, 但號碼已經失效的的名單
        create table plsport_playsport._fail_number engine = myisam
        SELECT concat('0',one) as phone, stas 
        FROM textcampaign.text_sent_status_0226
        where stas = '失敗';
        insert ignore into plsport_playsport._fail_number
        SELECT concat('0',one) as phone, stas 
        FROM textcampaign.text_sent_status
        where stas = '失敗';
        insert ignore into plsport_playsport._fail_number
        SELECT concat('0',phone) as phone, stas 
        FROM textcampaign.text_sent_status_0401
        where stas = '失敗'; 
        insert ignore into plsport_playsport._fail_number
        SELECT phone, stas 
        FROM textcampaign.text_sent_status_0501_a
        where stas = '失敗';  
        insert ignore into plsport_playsport._fail_number
        SELECT phone, stas 
        FROM textcampaign.text_sent_status_0501_c
        where stas = '失敗';  
        
        create table plsport_playsport._fail_number_1 engine = myisam
        SELECT phone, stas 
        FROM plsport_playsport._fail_number
        group by phone, stas;

#排除掉號碼已經失效的的名單
create table plsport_playsport._list_all_4 engine = myisam
SELECT  a.userid, a.phone, a.spent, a.coupon, a.spent1, a.coupon1 
FROM plsport_playsport._list_all_3 a left join plsport_playsport._fail_number_1 b on a.phone = b.phone
where b.phone is null;

#排除掉沒有號碼的人
create table plsport_playsport._list_all_5 engine = myisam
SELECT * FROM plsport_playsport._list_all_4
where phone is not null;


#誰是已經收到2次簡訊的人
create table plsport_playsport._who_receive_2_text engine = myisam
SELECT userid
FROM textcampaign.retention_c_20150401_full_list_dont_delete
where abtest = 'sent';
insert ignore into plsport_playsport._who_receive_2_text
SELECT userid
FROM textcampaign.retention_c_20150501_full_list_dont_delete
where abtest = 'sent';
    # 收到2次簡訊的名單, 這次沒有人
    select a.userid, a.c
    from (
        SELECT userid, count(userid) as c 
        FROM plsport_playsport._who_receive_2_text
        group by userid) as a
    where a.c = 2
    order by a.c desc;


#排除掉上回有收到簡訊的人
create table plsport_playsport._list_all_6 engine = myisam
SELECT a.userid, a.phone, a.spent, a.coupon, a.spent1, a.coupon1
FROM plsport_playsport._list_all_5 a left join textcampaign.retention_c_20150501_full_list_dont_delete b on a.userid = b.userid
where b.text_campaign is null;


#發送60%的人, 40%的人保留
create table plsport_playsport._list_all_7 engine = myisam
SELECT (b.id%10)+1 as g, (case when ((b.id%10)+1<7) then 'sent' else 'hold' end) as abtest, b.id, a.userid, a.phone, a.spent, a.coupon, a.spent1, a.coupon1, # 60%要發送
       (case when (a.userid is not null) then 'retention_c_20150605' else '' end) as text_campaign
FROM plsport_playsport._list_all_6 a left join plsport_playsport.member b on a.userid = b.userid;

create table textcampaign.retention_c_20150605_full_list_dont_delete engine = myisam
SELECT * FROM plsport_playsport._list_all_7;

        # 給yoyo8簡訊發送
        SELECT 'phone', '使用者編號id', '簡訊行銷' UNION (
        SELECT phone, id, text_campaign
        INTO outfile 'C:/Users/1-7_ASUS/Desktop/retention_c_20150605_for_yoyo8.csv'
        CHARACTER SET big5 fields terminated by ',' enclosed by '' lines terminated by '\r\n' 
        FROM textcampaign.retention_c_20150605_full_list_dont_delete
        WHERE abtest = 'sent'); # 只撈出有要發送的
        # 一定要設定為big編碼, yoyo8規定的

        # 給工程部匯入兌換券發送系統
        SELECT userid
        INTO outfile 'C:/Users/1-7_ASUS/Desktop/retention_c_20150605_for_software_team.csv'
        fields terminated by ',' enclosed by '' lines terminated by '\r\n' 
        FROM textcampaign.retention_c_20150605_full_list_dont_delete
        WHERE abtest = 'sent'; # 只撈出有要發送的
        
# 針對近期流失客的名單產生至此-------------------------------------------------------------------


# 以下是分析追蹤的部分 update: 2015-06-26
# 先匯入yoyo8的簡訊發送狀態記錄

create table textcampaign.text_sent_status_0605_c1 engine = myisam
SELECT concat(0,phone) as phone, type, stas, date, time, text_contect
FROM textcampaign.text_sent_status_0605_c;

drop table textcampaign.text_sent_status_0605_c;
rename table textcampaign.text_sent_status_0605_c1 to textcampaign.text_sent_status_0605_c;

# 主名單
create table textcampaign.text_sent_status_0605_c_1 engine = myisam
SELECT a.phone, a.userid, a.text_campaign, a.abtest as status, b.stas
FROM textcampaign.retention_c_20150605_full_list_dont_delete a left join textcampaign.text_sent_status_0605_c b on a.phone = b.phone;

# 回網站跳出訊息
CREATE TABLE textcampaign._coupon_window_pop_up engine = myisam
SELECT userid, outflowMember, (case when (outflowMember is not null) then 'see_pop' else '' end) as see
FROM plsport_playsport.showMessage
WHERE outflowmember is not null
AND outflowMember between '2015-06-05 18:00:00' AND '2015-06-08 23:59:59'
ORDER BY outflowMember;

# 有誰回網站看到領取抵用券提示視窗
create table textcampaign.text_sent_status_0605_c_2 engine = myisam
SELECT a.phone, a.userid, a.text_campaign, a.status, a.stas, b.see
FROM textcampaign.text_sent_status_0605_c_1 a left join textcampaign._coupon_window_pop_up b on a.userid = b.userid;

# 個人信箱獲得兌換券派送訊息( mailpcash_list蠻大的, 要捉很久)
CREATE TABLE textcampaign._receive_coupon engine = myisam
SELECT tou, title, date, remarks 
FROM plsport_playsport.mailpcash_list
WHERE title LIKE '%恭喜獲得兌換券%'
AND date between '2015-06-05 18:00:00' AND '2015-06-08 23:59:59';

# 有誰實際領取到抵用券
create table textcampaign.text_sent_status_0605_c_3 engine = myisam
SELECT a.phone, a.userid, a.text_campaign, a.status, a.stas, a.see, b.title 
FROM textcampaign.text_sent_status_0605_c_2 a left join textcampaign._receive_coupon b on a.userid = b.tou;


CREATE TABLE textcampaign._spent engine = myisam
SELECT userid, sum(amount) as spent
FROM plsport_playsport.pcash_log
WHERE payed = 1 AND type = 1
AND date between '2015-06-05 18:00:00' AND '2015-06-19 23:59:59'
GROUP BY userid;

# 加上期間內消費多少金額
create table textcampaign.text_sent_status_0605_c_4 engine = myisam
SELECT a.phone, a.userid, a.text_campaign, a.status, a.stas, a.see, a.title, b.spent
FROM textcampaign.text_sent_status_0605_c_3 a left join textcampaign._spent b on a.userid = b.userid;

# a/b testing 計算機
# A>B
# C>D

#短期
#A
SELECT * FROM textcampaign.text_sent_status_0605_c_4
where status = 'sent' and stas = '成功';
#B
SELECT * FROM textcampaign.text_sent_status_0605_c_4
where status = 'sent' and stas = '成功' and spent is not null;
#C
SELECT * FROM textcampaign.text_sent_status_0605_c_4
where status = 'hold' and stas is null;
#D
SELECT * FROM textcampaign.text_sent_status_0605_c_4
where status = 'hold' and stas is null and spent is not null;

# 誰有回來網站
SELECT * FROM textcampaign.text_sent_status_0605_c_4
where see is not null;

# 誰有領到抵用券
SELECT * FROM textcampaign.text_sent_status_0605_c_4
where title is not null;

# 計算在期間內, 有使用抵用券的記錄
CREATE TABLE textcampaign._coupon_used engine = myisam
SELECT userid, count(id) as coupon_used_count 
FROM plsport_playsport.coupon_used_detail
WHERE type = 1
AND date between '2015-06-05 18:00:00' AND '2015-06-19 23:59:59'
GROUP BY userid; 

create table textcampaign.text_sent_status_0605_c_5 engine = myisam
SELECT a.phone, a.userid, a.text_campaign, a.status, a.stas, a.see, a.title, a.spent, b.coupon_used_count 
FROM textcampaign.text_sent_status_0605_c_4 a left join textcampaign._coupon_used b on a.userid = b.userid;

# 有誰在期間內用過抵用券
SELECT * FROM textcampaign.text_sent_status_0605_c_5
where status = 'sent' and stas = '成功' and see is not null and title is not null 
and coupon_used_count is not null;

# 有誰點過簡訊的連結
create table textcampaign._who_click_text_message engine = myisam 
SELECT userid, uri, time, platform_type
FROM actionlog.action_201506
where uri like '%retention%'
and time between '2015-06-05 18:00:00' and '2015-06-08 22:59:59';

# 點過簡訊的連結次數
select a.cam, count(a.uri) as c
from (
    SELECT userid, uri, time, platform_type, substr(uri, locate('utm_campaign=',uri)+23,1) as cam
    FROM textcampaign._who_click_text_message) as a
group by a.cam;

create table textcampaign._who_have_redeem engine = myisam
SELECT userid, sum(amount) as redeem, count(amount) as redeem_count 
FROM plsport_playsport.pcash_log
where payed = 1 and type in (3,4)
and date between '2015-06-05 18:00:00' AND '2015-06-19 23:59:59'
group by userid;

# 最後再檢查儲值金額
create table textcampaign.text_sent_status_0605_c_6 engine = myisam
SELECT a.phone, a.userid, a.text_campaign, a.status, a.stas, a.see, a.title, a.spent, a.coupon_used_count, b.redeem, b.redeem_count 
FROM textcampaign.text_sent_status_0605_c_5 a left join textcampaign._who_have_redeem b on a.userid = b.userid;

SELECT count(userid) as redeem_user_count, sum(redeem) as total_redeem_count 
FROM textcampaign.text_sent_status_0605_c_6
where status = 'sent' and stas = '成功' and spent is not null
and redeem is not null;

SELECT count(userid) as redeem_user_count, sum(redeem) as total_redeem_count
FROM textcampaign.text_sent_status_0605_c_6
where status = 'hold' and stas is null and spent is not null
and redeem is not null;







# update: 2015-07-10
# 補充之前3次長期流失客如果長期來看的話, 會不會有什麼差異

use textcampaign;

create table textcampaign._cam1 engine = myisam
SELECT a.phone, a.userid, a.text_campaign, a.status
FROM textcampaign.retention_20150114_full_list_dont_delete a 
left join (SELECT concat('0',one) as phone, stas 
           FROM textcampaign.text_sent_status) as b on a.phone = b.phone
where b.stas is null;

create table textcampaign._cam2 engine = myisam
SELECT a.phone, a.userid, a.text_campaign, a.status
FROM textcampaign.retention_20150226_full_list_dont_delete a 
left join (SELECT concat('0',one) as phone, stas 
           FROM textcampaign.text_sent_status_0226) as b on a.phone = b.phone
where b.stas = '成功 ' OR b.stas is null;

create table textcampaign._cam3 engine = myisam
SELECT a.phone, a.userid, a.text_campaign, a.status, b.stas
FROM textcampaign.retention_a_20150501_full_list_dont_delete a
left join (SELECT phone, stas 
           FROM textcampaign.text_sent_status_0501_a) as b on a.phone = b.phone
where b.stas = '成功 ' OR b.stas is null;


create table textcampaign._redeem_1 engine = myisam
SELECT userid, sum(amount) as redeem, count(amount) as redeem_count
FROM plsport_playsport.pcash_log
where payed = 1 and type in (3,4)
and date(date) between '2015-01-15' and now()
group by userid;

create table textcampaign._redeem_2 engine = myisam
SELECT userid, sum(amount) as redeem, count(amount) as redeem_count
FROM plsport_playsport.pcash_log
where payed = 1 and type in (3,4)
and date(date) between '2015-02-27' and now()
group by userid;

create table textcampaign._redeem_3 engine = myisam
SELECT userid, sum(amount) as redeem, count(amount) as redeem_count
FROM plsport_playsport.pcash_log
where payed = 1 and type in (3,4)
and date(date) between '2015-05-02' and now()
group by userid;

create table textcampaign._buy_1 engine = myisam
SELECT userid, sum(amount) as spent, count(amount) as spent_count
FROM plsport_playsport.pcash_log
where payed = 1 and type = 1
and date(date) between '2015-01-15' and now()
group by userid;

create table textcampaign._buy_2 engine = myisam
SELECT userid, sum(amount) as spent, count(amount) as spent_count
FROM plsport_playsport.pcash_log
where payed = 1 and type = 1
and date(date) between '2015-02-27' and now()
group by userid;

create table textcampaign._buy_3 engine = myisam
SELECT userid, sum(amount) as spent, count(amount) as spent_count
FROM plsport_playsport.pcash_log
where payed = 1 and type = 1
and date(date) between '2015-05-02' and now()
group by userid;

create table textcampaign._cam1_list engine = myisam
select c.userid, c.status, c.redeem, c.redeem_count, d.spent, d.spent_count
from (
    SELECT a.userid, a.status, b.redeem, b.redeem_count
    FROM textcampaign._cam1 a left join textcampaign._redeem_1 b on a.userid = b.userid) as c
    left join textcampaign._buy_1 d on c.userid = d.userid;

create table textcampaign._cam2_list engine = myisam
select c.userid, c.status, c.redeem, c.redeem_count, d.spent, d.spent_count
from (
    SELECT a.userid, a.status, b.redeem, b.redeem_count
    FROM textcampaign._cam2 a left join textcampaign._redeem_2 b on a.userid = b.userid) as c
    left join textcampaign._buy_2 d on c.userid = d.userid;
    
create table textcampaign._cam3_list engine = myisam
select c.userid, c.status, c.redeem, c.redeem_count, d.spent, d.spent_count
from (
    SELECT a.userid, a.status, b.redeem, b.redeem_count
    FROM textcampaign._cam3 a left join textcampaign._redeem_3 b on a.userid = b.userid) as c
    left join textcampaign._buy_3 d on c.userid = d.userid;


SELECT 'userid', 'status', 'redeem', 'redeem_count','spent','spent_count'union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_cam1_list.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM textcampaign._cam1_list);

SELECT 'userid', 'status', 'redeem', 'redeem_count','spent','spent_count'union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_cam2_list.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM textcampaign._cam2_list);

SELECT 'userid', 'status', 'redeem', 'redeem_count','spent','spent_count'union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_cam3_list.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM textcampaign._cam3_list);








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
    drop TABLE if exists plsport_playsport._predict_buyer;
    drop TABLE if exists plsport_playsport._predict_buyer_with_cons;

    #先predict_buyer + predict_buyer_cons_split
    CREATE TABLE plsport_playsport._predict_buyer engine = myisam
    SELECT a.id, a.buyerid, a.id_bought, a.buy_date , a.buy_price, b.position, b.cons, b.allianceid
    FROM plsport_playsport.predict_buyer a LEFT JOIN plsport_playsport.predict_buyer_cons_split b on a.id = b.id_predict_buyer
    WHERE a.buy_price <> 0
    AND a.buy_date between '2014-03-04 00:00:00' AND '2016-12-31 23:59:59'; #2014/03/04是開始有購牌追蹤代碼的日子

        ALTER TABLE plsport_playsport._predict_buyer ADD INDEX (`id_bought`);  

    #再join predict_seller
    CREATE TABLE plsport_playsport._predict_buyer_with_cons engine = myisam
    SELECT c.id, c.buyerid, c.id_bought, d.sellerid ,c.buy_date , c.buy_price, c.position, c.cons, c.allianceid
    FROM plsport_playsport._predict_buyer c LEFT JOIN plsport_playsport.predict_seller d on c.id_bought = d.id
    ORDER BY buy_date DESC;
# ------------------------------------------------------------------------------------------------

# 先撈出符合的records
CREATE TABLE plsport_playsport._predict_buyer_with_cons_1 engine = myisam
SELECT id, buyerid, id_bought, sellerid, buy_date, buy_price, position, cons, allianceid, substr(position,1,3) as p
FROM plsport_playsport._predict_buyer_with_cons
WHERE buy_date between '2014-05-01 00:00:00' AND '2014-06-30 23:59:59' # 區間
AND position is not null; # 過瀘掉沒有records

CREATE TABLE plsport_playsport._list_1 engine = myisam # 主名單
SELECT buyerid, count(buyerid) as c 
FROM plsport_playsport._predict_buyer_with_cons_1
WHERE p in ('IDX', 'BRC')
GROUP BY buyerid;

CREATE TABLE plsport_playsport._list_pay_idx engine = myisam # 用首頁買的人
SELECT buyerid, sum(buy_price) as pay_idx 
FROM plsport_playsport._predict_buyer_with_cons_1
WHERE p in ('IDX')
GROUP BY buyerid;

CREATE TABLE plsport_playsport._list_pay_brc engine = myisam # 用購牌後推廌專區買的人
SELECT buyerid, sum(buy_price) as pay_brc 
FROM plsport_playsport._predict_buyer_with_cons_1
WHERE p in ('BRC')
GROUP BY buyerid;

CREATE TABLE plsport_playsport._list_order_data engine = myisam # 總儲值金額
SELECT userid, sum(price) as total_redeem 
FROM plsport_playsport.order_data
WHERE payway in (1,2,3,4,5,6,9,10) 
AND sellconfirm = 1
GROUP BY userid;

CREATE TABLE plsport_playsport._list_pcash_log engine = myisam # 近3個月購買金額
SELECT userid, sum(amount) as total_paid 
FROM plsport_playsport.pcash_log
WHERE payed = 1 AND type = 1 
AND date between subdate(now(),93) AND now() # 近3個月
GROUP BY userid;

CREATE TABLE plsport_playsport._last_signin engine = myisam # 最近一次登入
SELECT userid, max(signin_time) as last_signin
FROM plsport_playsport.member_signin_log_archive
GROUP BY userid;

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


CREATE TABLE plsport_playsport._list_2 engine = myisam # 主名單
SELECT i.buyerid, i.nickname, i.join_date, i.total_redeem, i.total_paid, i.pay_idx, j.pay_brc
FROM (
    SELECT g.buyerid, g.nickname, g.join_date, g.total_redeem, g.total_paid, h.pay_idx 
    FROM (
        SELECT e.buyerid, e.nickname, e.join_date, e.total_redeem, f.total_paid 
        FROM (
            SELECT c.buyerid, c.nickname, c.join_date, d.total_redeem 
            FROM (
                SELECT a.buyerid, b.nickname, date(b.CREATEon) as join_date
                FROM plsport_playsport._list_1 a LEFT JOIN plsport_playsport.member b on a.buyerid = b.userid) as c
                LEFT JOIN plsport_playsport._list_order_data as d on c.buyerid = d.userid) as e
            LEFT JOIN plsport_playsport._list_pcash_log as f on e.buyerid = f.userid) as g
        LEFT JOIN plsport_playsport._list_pay_idx as h on g.buyerid = h.buyerid) as i
    LEFT JOIN plsport_playsport._list_pay_brc as j on i.buyerid = j.buyerid;

    ALTER TABLE plsport_playsport._list_2 ADD INDEX (`buyerid`); 
    ALTER TABLE  `_list_2` CHANGE  `nickname`  `nickname` CHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ;

SELECT 'userid', 'nickname', 'join_date', 'total_redeem', 'total_paid', 'pay_idx', 'pay_brc', 'last_signin' UNION (
SELECT a.buyerid, a.nickname, a.join_date, a.total_redeem, a.total_paid, a.pay_idx, a.pay_brc, b.last_signin
INTO outfile 'C:/Users/1-7_ASUS/Desktop/survey_list_20140603.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM plsport_playsport._list_2 as a LEFT JOIN plsport_playsport._last_signin as b on a.buyerid = b.userid);

        # 檢查
        SELECT a.phone, a.id, a.text_campaign, a.abtest_group, b.text_campaign 
        FROM textcampaign._list6 a LEFT JOIN textcampaign.retention_201406_full_list_dont_delete b on a.id = b.id
        WHERE b.text_campaign is not null;



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
    drop TABLE if exists plsport_playsport._predict_buyer;
    drop TABLE if exists plsport_playsport._predict_buyer_with_cons;

    #先predict_buyer + predict_buyer_cons_split
    CREATE TABLE plsport_playsport._predict_buyer engine = myisam
    SELECT a.id, a.buyerid, a.id_bought, a.buy_date , a.buy_price, b.position, b.cons, b.allianceid
    FROM plsport_playsport.predict_buyer a LEFT JOIN plsport_playsport.predict_buyer_cons_split b on a.id = b.id_predict_buyer
    WHERE a.buy_price <> 0
    AND a.buy_date between '2014-03-04 00:00:00' AND '2016-12-31 23:59:59'; #2014/03/04是開始有購牌追蹤代碼的日子

        ALTER TABLE plsport_playsport._predict_buyer ADD INDEX (`id_bought`);  

    #再join predict_seller
    CREATE TABLE plsport_playsport._predict_buyer_with_cons engine = myisam
    SELECT c.id, c.buyerid, c.id_bought, d.sellerid ,c.buy_date , c.buy_price, c.position, c.cons, c.allianceid
    FROM plsport_playsport._predict_buyer c LEFT JOIN plsport_playsport.predict_seller d on c.id_bought = d.id
    ORDER BY buy_date DESC;
# ------------------------------------------------------------------------------------------------

# 先撈出符合的records
CREATE TABLE plsport_playsport._predict_buyer_with_cons_1 engine = myisam
SELECT id, buyerid, id_bought, sellerid, buy_date, buy_price, position, cons, allianceid, substr(position,1,2) as p
FROM plsport_playsport._predict_buyer_with_cons
WHERE buy_date between '2014-05-01 00:00:00' AND '2014-05-31 23:59:59' # 區間
AND position is not null; # 過瀘掉沒有records

CREATE TABLE plsport_playsport._list_1 engine = myisam 
SELECT *
FROM plsport_playsport._predict_buyer_with_cons_1
WHERE p in ('HT','BZ') 
AND position not in ('BZ_MF','BZ_SK'); #排除掉購牌專區左邊欄位

CREATE TABLE plsport_playsport._list_2 engine = myisam 
SELECT ((b.id%10)+1) as g, a.buyerid, a.sellerid, a.buy_date, a.buy_price, a.position, a.cons, a.allianceid, a.p 
FROM plsport_playsport._list_1 a LEFT JOIN plsport_playsport.member b on a.buyerid = b.userid;


CREATE TABLE plsport_playsport._list_3 engine = myisam 
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

CREATE TABLE plsport_playsport._list_4 engine = myisam
SELECT g, position, p, e, buyerid, sum(buy_price) as revenue 
FROM plsport_playsport._list_3
GROUP BY buyerid;

SELECT 'g', 'position', 'p', 'e', 'buyerid', 'revenue' UNION (
SELECT * 
INTO outfile 'C:/Users/1-7_ASUS/Desktop/title_change_measure.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM plsport_playsport._list_4
ORDER BY revenue DESC);

SELECT 'userid', 'nickname', 'join_date', 'total_redeem', 'total_paid', 'pay_idx', 'pay_brc', 'last_signin' UNION (
SELECT a.buyerid, a.nickname, a.join_date, a.total_redeem, a.total_paid, a.pay_idx, a.pay_brc, b.last_signin
INTO outfile 'C:/Users/1-7_ASUS/Desktop/survey_list_20140603.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM plsport_playsport._list_2 as a LEFT JOIN plsport_playsport._last_signin as b on a.buyerid = b.userid);



# =================================================================================================
#  2014-06-05 (阿達)
#  [201402-B-1] 加高國際讓分、主推版標比重 - A/B testing
#  計算點擊pv的情況
# =================================================================================================

CREATE TABLE actionlog._change_action_201405 engine = myisam
SELECT userid, uri, time
FROM actionlog.action_201405
WHERE userid <> ''
AND uri LIKE '%rp=%';

CREATE TABLE actionlog._change_action_201405_1 engine = myisam
SELECT userid, substr(uri,locate('rp=',uri)+3,length(uri)) as p, time 
FROM actionlog._change_action_201405;

CREATE TABLE actionlog._change_action_201405_2 engine = myisam
SELECT userid, p, time
FROM actionlog._change_action_201405_1
WHERE substr(p,1,2) in ('BZ','HT')
AND p not in ('BZ_MF','BZ_SK');

ALTER TABLE  `_change_action_201405_2` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

CREATE TABLE actionlog._change_action_201405_3 engine = myisam
SELECT ((b.id%10)+1) as g, a.userid, a.p, a.time
FROM actionlog._change_action_201405_2 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

CREATE TABLE actionlog._change_action_201405_4 engine = myisam
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

CREATE TABLE actionlog._change_action_201406 engine = myisam
SELECT userid, uri, time
FROM actionlog.action_201406
WHERE userid <> ''
AND uri LIKE '%rp=%';

CREATE TABLE actionlog._change_action_201406_1 engine = myisam
SELECT userid, substr(uri,locate('rp=',uri)+3,length(uri)) as p, time 
FROM actionlog._change_action_201406;

CREATE TABLE actionlog._change_action_201406_2 engine = myisam
SELECT userid, p, time
FROM actionlog._change_action_201406_1
WHERE substr(p,1,2) in ('BZ','HT')
AND p not in ('BZ_MF','BZ_SK');

ALTER TABLE  actionlog._change_action_201406_2 CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

CREATE TABLE actionlog._change_action_201406_3 engine = myisam
SELECT ((b.id%10)+1) as g, a.userid, a.p, a.time
FROM actionlog._change_action_201406_2 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

CREATE TABLE actionlog._change_action_201406_4 engine = myisam
SELECT * FROM actionlog._change_action_201406_3
WHERE time between '2014-06-10 00:00:00' AND '2014-06-22 23:59:59'; #--------------主要篩選區間


CREATE TABLE actionlog._change_action_201406_5 engine = myisam
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


CREATE TABLE actionlog._change_action_201406_6 engine = myisam 
SELECT * #----------------------------------------------------沒參加實驗的
FROM actionlog._change_action_201406_5
WHERE g in (1,2,3,4,5,6,10) AND ver = 'raw';
INSERT IGNORE INTO actionlog._change_action_201406_6
SELECT * #----------------------------------------------------有參加實驗的
FROM actionlog._change_action_201406_5
WHERE g in (7,8,9) AND ver = 'edited';

SELECT a.g, count(a.userid) as c #-------------點頭3標的人數
FROM (
    SELECT g, pp, userid, count(userid) as c
    FROM actionlog._change_action_201406_6
    WHERE pp = 'HT'
    GROUP BY g, ver, userid) as a
GROUP BY a.g;

SELECT a.g, count(a.userid) as c #-------------點推廌專區的人數
FROM (
    SELECT g, pp, userid, count(userid) as c
    FROM actionlog._change_action_201406_6
    WHERE pp = 'BZ'
    GROUP BY g, ver, userid) as a
GROUP BY a.g;


CREATE TABLE actionlog._change_action_201406_7_for_r engine = myisam 
SELECT g, pp, userid, count(userid) as c
FROM actionlog._change_action_201406_6
WHERE pp = 'HT'
GROUP BY g, ver, userid;
INSERT IGNORE INTO actionlog._change_action_201406_7_for_r
SELECT g, pp, userid, count(userid) as c
FROM actionlog._change_action_201406_6
WHERE pp = 'BZ'
GROUP BY g, ver, userid;

# 輸出給R, 跑a/b testing檢定
SELECT 'g', 'p', 'userid', 'c' UNION(
SELECT * 
INTO outfile 'C:/Users/1-7_ASUS/Desktop/change_action_201406_7_for_r.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM actionlog._change_action_201406_7_for_r);

#-----------2014/07/07---------------------------------------------------------------------

CREATE TABLE plsport_playsport._predict_buyer_with_cons_1 engine = myisam
SELECT * 
FROM plsport_playsport._predict_buyer_with_cons
WHERE buy_date between '2014-06-10 00:00:00' AND '2014-06-22 23:59:59'
AND substr(position,1,2) in ('HT','BZ');

CREATE TABLE plsport_playsport._predict_buyer_with_cons_2 engine = myisam
SELECT *
FROM (
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
WHERE a.ver <> 'XXXXX';

CREATE TABLE plsport_playsport._predict_buyer_with_cons_3 engine = myisam
SELECT (b.id%10)+1 as g, a.buyerid, a.buy_price, a.position, a.ver, a.p 
FROM plsport_playsport._predict_buyer_with_cons_2 a LEFT JOIN plsport_playsport.member b on a.buyerid = b.userid;

SELECT g, p, ver, sum(buy_price) as revenue 
FROM plsport_playsport._predict_buyer_with_cons_3
GROUP BY g, p, ver
ORDER BY p, g;

CREATE TABLE plsport_playsport._predict_buyer_with_cons_4 engine = myisam 
SELECT * 
FROM plsport_playsport._predict_buyer_with_cons_3
WHERE g in (1,2,3,4,5,6,10) AND ver = 'raw';
INSERT IGNORE INTO plsport_playsport._predict_buyer_with_cons_4
SELECT *
FROM plsport_playsport._predict_buyer_with_cons_3
WHERE g in (7,8,9) AND ver = 'edited';

CREATE TABLE plsport_playsport._predict_buyer_with_cons_5 engine = myisam
SELECT g, p, buyerid as userid, sum(buy_price) as revenue
FROM plsport_playsport._predict_buyer_with_cons_4
WHERE p = 'HT'
GROUP BY g, ver, buyerid;
INSERT IGNORE INTO plsport_playsport._predict_buyer_with_cons_5
SELECT g, p, buyerid as userid, sum(buy_price) as revenue
FROM plsport_playsport._predict_buyer_with_cons_4
WHERE p = 'BZ'
GROUP BY g, ver, buyerid;


# 輸出給R, 跑a/b testing檢定
SELECT 'g', 'p', 'userid', 'revenue' UNION(
SELECT * 
INTO outfile 'C:/Users/1-7_ASUS/Desktop/predict_buyer_with_cons_5.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM plsport_playsport._predict_buyer_with_cons_5);


SELECT g, count(userid) as c 
FROM plsport_playsport._predict_buyer_with_cons_5
WHERE p = 'BZ'
GROUP BY g;

SELECT g, sum(revenue) as c 
FROM plsport_playsport._predict_buyer_with_cons_5
WHERE p = 'BZ'
GROUP BY g;


#-----------2014/08/19---------------------------------------------------------------------
# to Eddy :
# 已上第三階段 A/B testing，預計測試時間 7/29 ~ 8/26
# 麻煩再評估一下報告時間
# p.s. 這次只動到頭三標，沒有影響到購牌專區推薦專區，故只需做頭三標報告即可

CREATE TABLE actionlog._action_201405_position engine = myisam
SELECT userid, uri, time
FROM actionlog.action_201405
WHERE userid <> '' AND uri LIKE '%rp=%';

CREATE TABLE actionlog._action_201406_position engine = myisam
SELECT userid, uri, time
FROM actionlog.action_201406
WHERE userid <> '' AND uri LIKE '%rp=%';

CREATE TABLE actionlog._action_201407_position engine = myisam
SELECT userid, uri, time
FROM actionlog.action_201407
WHERE userid <> '' AND uri LIKE '%rp=%';

CREATE TABLE actionlog._action_201408_position engine = myisam
SELECT userid, uri, time
FROM actionlog.action_201408_edited
WHERE userid <> '' AND uri LIKE '%rp=%';

CREATE TABLE actionlog._action_position engine = myisam SELECT * FROM actionlog._action_201405_position;
INSERT IGNORE INTO actionlog._action_position SELECT * FROM actionlog._action_201406_position;
INSERT IGNORE INTO actionlog._action_position SELECT * FROM actionlog._action_201407_position;
INSERT IGNORE INTO actionlog._action_position SELECT * FROM actionlog._action_201408_position;

# (1) 先捉出代碼和篩出時間區間
CREATE TABLE actionlog._action_position_1 engine = myisam
SELECT userid, uri, substr(uri, locate('&rp=',uri)+4, length(uri)) as rp, time 
FROM actionlog._action_position
WHERE time between '2014-05-12 12:00:00' AND '2014-08-19 00:00:00';

# (2) 再去掉代碼&之後的string
CREATE TABLE actionlog._action_position_2 engine = myisam
SELECT userid, uri, (case when (locate('&',rp)=0) then rp else substr(rp,1,(locate('&',rp))) end) as rp, time
FROM actionlog._action_position_1;

# (3) 最後比對第1碼是大寫的,排除掉一些有的沒的string, user"abc36611"的string很奇怪, 直接排掉此人
CREATE TABLE actionlog._action_position_3 engine = myisam
SELECT * 
FROM actionlog._action_position_2
WHERE substr(rp,1,1) REGEXP BINARY '[A-Z]' 
or userid <> 'abc36611'; #words which have 1 capital letters consecutively

# Regexp - How to find capital letters in MySQL only
# http://stackoverflow.com/questions/8666796/regexp-how-to-find-capital-letters-in-mysql-only
# WHERE names REGEXP BINARY '[A-Z]{2}'
# REGEXP is not case sensitive, except when used with binary strings.
# 要順便檢查一下目前到底有多少位置

# (4) 最後, 所有目前的位置代碼表, 只要查詢就好
SELECT rp, count(userid) as c 
FROM actionlog._action_position_3
GROUP BY rp;


# 這個部分才開始做任務的研究

CREATE TABLE actionlog._action_position_3_HT_only engine = myisam
SELECT * 
FROM actionlog._action_position_3
WHERE substr(rp,1,2) = 'HT' 
AND time between '2014-07-29 12:00:00' AND '2014-08-31: 00:00:00';


CREATE TABLE actionlog._action_position_3_HT_only_ok engine = myisam
SELECT d.g, d.userid, d.rp, d.version, d.time
FROM (
    SELECT c.g, c.userid, c.rp, c.version, c.time, (case when (g>13) then 'B' else 'A' end) as chk
    FROM (
        SELECT (b.id%20)+1 as g, a.userid, a.rp, substr(a.rp,5,1) as version, a.time
        FROM actionlog._action_position_3_ht_only a LEFT JOIN plsport_playsport.member b on a.userid = b.userid) as c) as d
WHERE d.version = d.chk;


SELECT version, count(g) as c 
FROM actionlog._action_position_3_ht_only_ok
GROUP BY version;

SELECT a.rp, count(a.userid) as c
FROM (
    SELECT * FROM actionlog._action_position_3
    WHERE substr(rp,1,2) = 'US'
    AND time between '2014-08-15 18:00:00' AND '2014-08-18 12:00:00') as a
GROUP BY a.rp;


# 每個使用者點擊頭3標的次數, 可輸出.csv
CREATE TABLE actionlog._action_position_3_HT_only_click_count engine = myisam
SELECT g, userid, version, count(userid) as click 
FROM actionlog._action_position_3_ht_only_ok
GROUP BY g, userid, version;


CREATE TABLE plsport_playsport._predict_buyer_with_cons_only_ht engine = myisam
SELECT buyerid as userid, buy_date, buy_price, position, substr(position,5,1) as version
FROM plsport_playsport._predict_buyer_with_cons
WHERE buy_date between '2014-07-29 12:00:00' AND '2014-08-31: 00:00:00'
AND substr(position,1,2) = 'HT'
ORDER BY buy_date DESC;


CREATE TABLE plsport_playsport._predict_buyer_with_cons_only_ht_revenue engine = myisam
SELECT d.g, d.userid, d.buy_date, d.buy_price, d.position, d.version
FROM (
    SELECT c.g, c.userid, c.buy_date, c.buy_price, c.position, c.version, (case when (c.g>13) then 'B' else 'A' end) as chk
    FROM (
        SELECT (b.id%20)+1 as g, a.userid, a.buy_date, a.buy_price, a.position, a.version 
        FROM plsport_playsport._predict_buyer_with_cons_only_ht a LEFT JOIN plsport_playsport.member b on a.userid = b.userid) as c) as d
WHERE d.version = d.chk;

# 每個使用者購買頭3標的金額, 可輸出.csv
CREATE TABLE plsport_playsport._predict_buyer_with_cons_only_ht_revenue_ok engine = myisam
SELECT g, userid, version, sum(buy_price) as spent
FROM plsport_playsport._predict_buyer_with_cons_only_ht_revenue
GROUP BY g, userid, version;

SELECT version, count(userid), sum(click)  
FROM actionlog._action_position_3_ht_only_click_count
GROUP BY version;

SELECT version, count(userid), sum(spent) 
FROM plsport_playsport._predict_buyer_with_cons_only_ht_revenue_ok
GROUP BY version;



# =================================================================================================
#  2014-06-10
#　[201406-A-1] 個人預測頁左下欄位改成戰績 - 數據研究
#  1. 近半年有消費者的使用者，半年內看個分類戰績的比例 ( 戰績總覽、本月、上月、本週、上週、本賽季、總計 )
#  2. 請排除自己看自己的戰績記錄
# =================================================================================================

# 這個任務是要撈出個人頁>戰績頁中的所有log, 並利用uri來分析使用者都是怎麼使用戰績貢
# 先撈出1月~5月的個人頁log
CREATE TABLE actionlog.action_201405_visit_member engine = myisam
SELECT userid, uri, time FROM actionlog.action_201405 WHERE userid <> '' AND uri LIKE '%visit_member.php%';
CREATE TABLE actionlog.action_201404_visit_member engine = myisam
SELECT userid, uri, time FROM actionlog.action_201404 WHERE userid <> '' AND uri LIKE '%visit_member.php%';
CREATE TABLE actionlog.action_201403_visit_member engine = myisam
SELECT userid, uri, time FROM actionlog.action_201403 WHERE userid <> '' AND uri LIKE '%visit_member.php%';
CREATE TABLE actionlog.action_201402_visit_member engine = myisam
SELECT userid, uri, time FROM actionlog.action_201402 WHERE userid <> '' AND uri LIKE '%visit_member.php%';
CREATE TABLE actionlog.action_201401_visit_member engine = myisam
SELECT userid, uri, time FROM actionlog.action_201401 WHERE userid <> '' AND uri LIKE '%visit_member.php%';

# 再把1月~5月的個人頁log合併成一個檔
    CREATE TABLE actionlog.action_visit_member engine = myisam SELECT * FROM actionlog.action_201401_visit_member;
    INSERT IGNORE INTO actionlog.action_visit_member SELECT * FROM actionlog.action_201402_visit_member;
    INSERT IGNORE INTO actionlog.action_visit_member SELECT * FROM actionlog.action_201403_visit_member;
    INSERT IGNORE INTO actionlog.action_visit_member SELECT * FROM actionlog.action_201404_visit_member;
    INSERT IGNORE INTO actionlog.action_visit_member SELECT * FROM actionlog.action_201405_visit_member;


# 接下來的步驟就是在解析uri, 把uri中的變數一個個分出來
# (1) 分出visit
    CREATE TABLE actionlog.action_visit_member_1 engine = myisam
    SELECT userid, uri, substr(uri,locate('visit=',uri)+6) as u, time
    FROM actionlog.action_visit_member;

    CREATE TABLE actionlog.action_visit_member_2 engine = myisam
    SELECT userid, uri, 
           (case when (locate('&',u) = 0) then u
                 when (locate('&',u) > 0) then substr(u,1,locate('&',u)-1) end) as visit, time
    FROM actionlog.action_visit_member_1;
# (2) 分出action
    CREATE TABLE actionlog.action_visit_member_3 engine = myisam
    SELECT userid, uri, visit,
           (case when (locate('action=',uri) = 0) then null
                 when (locate('action=',uri) > 0) then substr(uri,locate('action=',uri)+7) end) as u, time
    FROM actionlog.action_visit_member_2;

    CREATE TABLE actionlog.action_visit_member_4 engine = myisam
    SELECT userid, uri, visit,
           (case when (locate('&',u) = 0) then null
                 when (locate('&',u) > 0) then substr(u,1,locate('&',u)-1) end) as action, time 
    FROM actionlog.action_visit_member_3;
# (3) 分出type
    CREATE TABLE actionlog.action_visit_member_5 engine = myisam
    SELECT userid, uri, visit, action,
           (case when (locate('&type=',uri) = 0) then null
                 when (locate('&type=',uri) > 0) then substr(uri,locate('&type=',uri)+6) end) as u, time
    FROM actionlog.action_visit_member_4;

    CREATE TABLE actionlog.action_visit_member_6 engine = myisam
    SELECT userid, uri, visit, action,
           (case when (locate('&',u) = 0) then null
                 when (locate('&',u) > 0) then substr(u,1,locate('&',u)-1) end) as type, time 
    FROM actionlog.action_visit_member_5;
# (4) 分出during
    CREATE TABLE actionlog.action_visit_member_7 engine = myisam
    SELECT userid, uri, visit, action, type,
           (case when (locate('during=',uri) = 0) then null
                 when (locate('during=',uri) > 0) then substr(uri,locate('during=',uri)+7) end) as u, time
    FROM actionlog.action_visit_member_6;

    CREATE TABLE actionlog.action_visit_member_8 engine = myisam
    SELECT userid, uri, visit, action, type,
           (case when (locate('&',u) = 0) then null
                 when (locate('&',u) > 0) then substr(u,1,locate('&',u)-1) end) as during, time 
    FROM actionlog.action_visit_member_7;
# (5) 分出vol
    CREATE TABLE actionlog.action_visit_member_9 engine = myisam
    SELECT userid, uri, visit, action, type, during,
           (case when (locate('vol=',uri) = 0) then null
                 when (locate('vol=',uri) > 0) then substr(uri,locate('vol=',uri)+4) end) as u, time
    FROM actionlog.action_visit_member_8;

    CREATE TABLE actionlog.action_visit_member_10 engine = myisam
    SELECT userid, uri, visit, action, type, during, 
           (case when (locate('&',u) = 0) then null
                 when (locate('&',u) > 0) then substr(u,1,locate('&',u)-1) end) as vol, time 
    FROM actionlog.action_visit_member_9;
# (6) 分出gameday
    CREATE TABLE actionlog.action_visit_member_11 engine = myisam
    SELECT userid, uri, visit, action, type, during, vol, 
           (case when (locate('gameday=',uri) = 0) then null
                 when (locate('gameday=',uri) > 0) then substr(uri,locate('gameday=',uri)+8) end) as u, time
    FROM actionlog.action_visit_member_10;

    CREATE TABLE actionlog.action_visit_member_12 engine = myisam
    SELECT userid, uri, visit, action, type, during, vol,
           (case when (locate('&',u) = 0) then u
                 when (locate('&',u) > 0) then substr(u,1,locate('&',u)-1) end) as gameday, time 
    FROM actionlog.action_visit_member_11;

    rename TABLE actionlog.action_visit_member_12 to actionlog.action_visit_member_edited;
# 在這個步驟要把textfield換成其它字串類型的變數, 要不然下group會很久
# action_visit_member_edited為此任務主要的log檔
    ALTER TABLE actionlog.action_visit_member_edited CHANGE COLUMN `visit` `visit` CHAR(20) NULL DEFAULT NULL COLLATE 'utf8_general_ci';
    ALTER TABLE actionlog.action_visit_member_edited CHANGE COLUMN `action` `action` CHAR(20) NULL DEFAULT NULL COLLATE 'utf8_general_ci';
    ALTER TABLE actionlog.action_visit_member_edited CHANGE COLUMN `type` `type` CHAR(20) NULL DEFAULT NULL COLLATE 'utf8_general_ci';
    ALTER TABLE actionlog.action_visit_member_edited CHANGE COLUMN `during` `during` CHAR(20) NULL DEFAULT NULL COLLATE 'utf8_general_ci';
    ALTER TABLE actionlog.action_visit_member_edited CHANGE COLUMN `vol` `vol` CHAR(10) NULL DEFAULT NULL COLLATE 'utf8_general_ci';
    ALTER TABLE actionlog.action_visit_member_edited CHANGE COLUMN `gameday` `gameday` CHAR(20) NULL DEFAULT NULL COLLATE 'utf8_general_ci';

# 把戰績頁都獨立出來
CREATE TABLE actionlog.action_visit_member_edited_tab_records engine = myisam
SELECT * FROM actionlog.action_visit_member_edited
WHERE action = 'records';

    ALTER TABLE actionlog.action_visit_member_edited_tab_records CHANGE COLUMN `userid` `userid` CHAR(22) NOT NULL COLLATE 'utf8_general_ci';
    ALTER TABLE actionlog.action_visit_member_edited_tab_records CHANGE COLUMN `visit` `visit` CHAR(20) NULL DEFAULT NULL COLLATE 'utf8_general_ci';

# 近6個月內有消費的人
CREATE TABLE plsport_playsport._who_spent_in_six_months engine = myisam
SELECT a.userid, count(a.userid) as c
FROM (
    SELECT userid, date
    FROM plsport_playsport.pcash_log
    WHERE payed = 1 AND type = 1
    AND date between subdate(now(),180) AND now()
    ORDER BY date) as a
GROUP BY a.userid;

    ALTER TABLE plsport_playsport._who_spent_in_six_months ADD INDEX (`userid`);  

# [1]戰績頁的記錄_近6個月有消費過的人
CREATE TABLE actionlog.action_visit_member_edited_tab_records_who_spent engine = myisam
SELECT a.userid, a.uri, a.visit, a.action, a.type, a.during, a.vol, a.gameday, a.time, b.c 
FROM actionlog.action_visit_member_edited_tab_records a inner join plsport_playsport._who_spent_in_six_months b on a.userid = b.userid
WHERE a.userid <> a.visit; #排除掉自己看自己

        # 計算戰績頁中的各tab點擊(本月, 上月, 本週, 上週, 本賽季, 總計)
        SELECT a.during, count(a.userid) as c
        FROM (
            SELECT * 
            FROM actionlog.action_visit_member_edited_tab_records_who_spent
            WHERE type = 'all') as a #戰績頁
        GROUP BY a.during;

            SELECT count(userid)
            FROM actionlog.action_visit_member_edited_tab_records_who_spent
            WHERE type = 'sk'; # 可以換成 all勝率, index總覽, mf莊殺資格, sk單殺資訊


# [2]戰績頁的記錄_近6個月沒消費的人
CREATE TABLE actionlog.action_visit_member_edited_tab_records_who_not_spent engine = myisam
SELECT a.userid, a.uri, a.visit, a.action, a.type, a.during, a.vol, a.gameday, a.time, b.c
FROM actionlog.action_visit_member_edited_tab_records a LEFT JOIN plsport_playsport._who_spent_in_six_months b on a.userid = b.userid
WHERE a.userid <> a.visit #排除掉自己看自己
AND b.c is null; 

        # 計算戰績頁中的各tab點擊(本月, 上月, 本週, 上週, 本賽季, 總計)
        SELECT a.during, count(a.userid) as c
        FROM (
            SELECT * 
            FROM actionlog.action_visit_member_edited_tab_records_who_not_spent
            WHERE type = 'all') as a #戰績頁
        GROUP BY a.during;

            SELECT count(userid)
            FROM actionlog.action_visit_member_edited_tab_records_who_not_spent
            WHERE type = 'sf'; # 可以換成 all勝率, index總覽, mf莊殺資格, sk單殺資訊


# [3]戰績頁的記錄
CREATE TABLE actionlog.action_visit_member_edited_tab_records_everyone engine = myisam
SELECT userid, uri, visit, action, type, during, vol, gameday, time 
FROM actionlog.action_visit_member_edited_tab_records
WHERE userid <> visit; #排除掉自己看自己

        # 計算戰績頁中的各tab點擊(本月, 上月, 本週, 上週, 本賽季, 總計)
        SELECT a.during, count(a.userid) as c
        FROM (
            SELECT * 
            FROM actionlog.action_visit_member_edited_tab_records_everyone
            WHERE type = 'all') as a #戰績頁
        GROUP BY a.during;

            SELECT count(userid)
            FROM actionlog.action_visit_member_edited_tab_records_everyone
            WHERE type = 'mf'; # 可以換成 all勝率, index總覽, mf莊殺資格, sk單殺資訊


# [1]主個人頁log記錄 (排除自己看自己的)
CREATE TABLE actionlog.action_visit_member_edited_all_tab engine = myisam
SELECT userid, uri, visit, action, type, during, vol, gameday, time 
FROM actionlog.action_visit_member_edited
WHERE userid <> visit; #排除掉自己看自己

        # 全部的版本統計
        SELECT action, count(userid) as c  
        FROM actionlog.action_visit_member_edited
        GROUP BY action;

        # 排除自己看自己的統計
        SELECT action, count(userid) as c 
        FROM actionlog.action_visit_member_edited_all_tab
        GROUP BY action;


# [2]主個人頁log記錄-有消費的人 (排除自己看自己的)
CREATE TABLE actionlog.action_visit_member_edited_all_tab_who_spent engine = myisam
SELECT a.userid, a.uri, a.visit, a.action, a.type, a.during, a.vol, a.gameday, a.time, b.c 
FROM actionlog.action_visit_member_edited a inner join plsport_playsport._who_spent_in_six_months b on a.userid = b.userid
WHERE a.userid <> a.visit; #排除掉自己看自己

        SELECT action, count(userid) as c  
        FROM actionlog.action_visit_member_edited_all_tab_who_spent
        GROUP BY action;


# [3]主個人頁log記錄-沒有消費的人 (排除自己看自己的)
CREATE TABLE actionlog.action_visit_member_edited_all_tab_who_not_spent engine = myisam
SELECT a.userid, a.uri, a.visit, a.action, a.type, a.during, a.vol, a.gameday, a.time, b.c 
FROM actionlog.action_visit_member_edited a LEFT JOIN plsport_playsport._who_spent_in_six_months b on a.userid = b.userid
WHERE a.userid <> a.visit
AND b.c is null; #排除掉自己看自己

        SELECT action, count(userid) as c  
        FROM actionlog.action_visit_member_edited_all_tab_who_not_spent
        GROUP BY action;


# ---------------------------------------------
# 新增任務 2014-07-14
# 2. 統計個人預測頁感謝文、發文欄位點擊記錄
# 統計時間：6/20 ~ 7/3
# 報告時間：7/9
# 備註：兩個欄位分別有文章及"看全部"
# 任務狀態: 新建
# ---------------------------------------------

# 先撈出6月20日~7月13日的個人頁log
CREATE TABLE actionlog.action_201406_visit_member engine = myisam
SELECT userid, uri, time FROM actionlog.action_201406 WHERE userid <> '' AND uri LIKE '%visit_member.php%';
CREATE TABLE actionlog.action_201407_visit_member engine = myisam
SELECT userid, uri, time FROM actionlog.action_201407 WHERE userid <> '' AND uri LIKE '%visit_member.php%';

        # 再把6月20日~7月13日的個人頁log合併成一個檔
        CREATE TABLE actionlog.action_visit_member engine = myisam SELECT * FROM actionlog.action_201406_visit_member
        WHERE time between '2014-06-20 00:00:00' AND '2014-06-30 23:59:59';
        INSERT IGNORE INTO actionlog.action_visit_member SELECT * FROM actionlog.action_201407_visit_member;

# 先撈出6月20日~7月13日的文章內頁log
CREATE TABLE actionlog.action_201406_forumdetail engine = myisam
SELECT userid, uri, time FROM actionlog.action_201406 WHERE userid <> '' AND uri LIKE '%forumdetail.php%';
CREATE TABLE actionlog.action_201407_forumdetail engine = myisam
SELECT userid, uri, time FROM actionlog.action_201407 WHERE userid <> '' AND uri LIKE '%forumdetail.php%';

        # 再把6月20日~7月13日的文章內頁log合併成一個檔
        CREATE TABLE actionlog.action_forumdetail engine = myisam SELECT * FROM actionlog.action_201406_forumdetail
        WHERE time between '2014-06-20 00:00:00' AND '2014-06-30 23:59:59';
        INSERT IGNORE INTO actionlog.action_forumdetail SELECT * FROM actionlog.action_201407_forumdetail;

#以上SQL產生的是:
#    (1) actionlog.action_visit_member
#    (2) actionlog.action_forumdetail

#接下來執行上一段程式解uri

#個人頁的點擊數直接count action_visit_member_edited
#戰績頁的點擊數直接count action_visit_member_edited_tab_records

#在討論區的部分(看殺手的分析文+感謝文)
CREATE TABLE actionlog.action_forumdetail_edited engine = myisam
SELECT userid, uri,
       (case when locate("&post_FROM=",uri) = 0 then ''
       else substr(uri, locate("&post_FROM=",uri)+11, length(uri)) end) as s 
FROM actionlog.action_forumdetail;
#在個人頁的部分(看殺手全部的分析文+全部的感謝文)
CREATE TABLE actionlog.action_visit_member_edited_post_FROM engine = myisam
SELECT userid, uri, time,
       (case when locate("&post_FROM=",uri) = 0 then ''
       else substr(uri, locate("&post_FROM=",uri)+11, length(uri)) end) as s
FROM actionlog.action_visit_member_edited
WHERE uri LIKE '%post_FROM=%';


# (1)
SELECT count(userid) as c 
FROM actionlog.action_visit_member_edited;
# (2)
SELECT count(userid) as c 
FROM actionlog.action_visit_member_edited_tab_records;
# (3)
SELECT s, count(userid) as c 
FROM actionlog.action_forumdetail_edited
GROUP BY s;
# (4)
SELECT s, count(userid) as c 
FROM actionlog.action_visit_member_edited_post_FROM
GROUP BY s;

# (1)
SELECT count(a.userid) as user_count
FROM (
    SELECT userid, count(userid) as c 
    FROM actionlog.action_visit_member_edited
    GROUP BY userid) as a;
# (2)
SELECT count(a.userid) as user_count
FROM (
    SELECT userid, count(userid) as c 
    FROM actionlog.action_visit_member_edited_tab_records
    GROUP BY userid) as a;
# (3)
SELECT a.s, count(a.userid) as user_count
FROM (
    SELECT userid, s, count(userid) as c 
    FROM actionlog.action_forumdetail_edited
    WHERE s <> ''
    GROUP BY userid, s) as a
GROUP BY a.s;
# (4)
SELECT a.s, count(a.userid) as user_count
FROM (
    SELECT userid, s, count(userid) as c
    FROM actionlog.action_visit_member_edited_post_FROM
    GROUP BY userid, s) as a
GROUP BY a.s;


# 下面的部分是補上條件:
#     (1)排除自己看自己
#     (2)近6個月內有消費的人
#
# 需要再重新產生: 2014/7/21
#     (1) actionlog.action_visit_member_edited
#     (2) actionlog.action_forumdetail


# 套用條件 (1)排除自己看自己 (2)近6個月內有消費過的人
CREATE TABLE actionlog.action_visit_member_without_see_himself_1 engine = myisam
SELECT a.userid, a.uri, a.visit, a.action, a.type, a.during, a.vol, a.gameday, a.time
FROM actionlog.action_visit_member_edited a inner join plsport_playsport._who_spent_in_six_months b on a.userid = b.userid
WHERE a.userid <> a.visit;

CREATE TABLE actionlog.action_visit_member_without_see_himself_tab_records_1  ENGINE=MYISAM SELECT * FROM
    actionlog.action_visit_member_without_see_himself_1
WHERE
    action = 'records';

# 個人頁的點擊數直接count action_visit_member_edited
# 戰績頁的點擊數直接count action_visit_member_edited_tab_records

# action_forumdetail_edited需要比對出是誰發的文, 並排除自己看自己的文章

# (1) 分出subjectid
    CREATE TABLE actionlog.action_forumdetail_edited_1 engine = myisam
    SELECT userid, uri, s, substr(uri,locate('subjectid=',uri)+10) as u
    FROM actionlog.action_forumdetail_edited;

    CREATE TABLE actionlog.action_forumdetail_edited_2 engine = myisam
    SELECT userid, uri, s,
           (case when (locate('&',u) = 0) then u
                 when (locate('&',u) > 0) then substr(u,1,locate('&',u)-1) end) as subjectid
    FROM actionlog.action_forumdetail_edited_1;

    ALTER TABLE plsport_playsport.forum ADD INDEX (`subjectid`);  
    ALTER TABLE actionlog.action_forumdetail_edited_2 CHANGE  `subjectid`  `subjectid` LONGTEXT CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ;
    ALTER TABLE actionlog.action_forumdetail_edited_2 CHANGE  `subjectid`  `subjectid` VARCHAR( 30 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ;
    ALTER TABLE actionlog.action_forumdetail_edited_2 ADD INDEX (`subjectid`); 

CREATE TABLE actionlog.action_forumdetail_edited_3 engine = myisam
SELECT a.userid, a.uri, a.s, a.subjectid, b.postuser
FROM actionlog.action_forumdetail_edited_2 a LEFT JOIN plsport_playsport.forum b on a.subjectid = b.subjectid;

    ALTER TABLE  actionlog.action_forumdetail_edited_3 CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
    ALTER TABLE  actionlog.action_forumdetail_edited_3 CHANGE  `postuser`  `postuser` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ;
    ALTER TABLE  actionlog.action_forumdetail_edited_3 ADD INDEX (`userid`); 
    ALTER TABLE  plsport_playsport._who_spent_in_six_months ADD INDEX (`userid`); 

# 套用條件(第一次忘了這步驟)
CREATE TABLE actionlog.action_forumdetail_edited_4 engine = myisam
SELECT a.userid, a.uri, a.s, a.subjectid, a.postuser 
FROM actionlog.action_forumdetail_edited_3 a inner join plsport_playsport._who_spent_in_six_months b on a.userid = b.userid
WHERE a.userid <> a.postuser;


CREATE TABLE actionlog.action_visit_member_without_see_himself_2 engine = myisam
SELECT userid, uri, 
      (case when locate("&post_FROM=",uri) = 0 then ''
            else substr(uri, locate("&post_FROM=",uri)+11, length(uri)) end) as s
FROM actionlog.action_visit_member_without_see_himself_1
WHERE uri LIKE '%post_FROM=%';




# (1)
SELECT count(userid) as c FROM actionlog.action_visit_member_without_see_himself_1;
# (2)
SELECT count(userid) as c FROM actionlog.action_visit_member_without_see_himself_tab_records_1;
# (3)
SELECT a.s, count(a.userid) as c
FROM (
    SELECT *
    FROM actionlog.action_forumdetail_edited_4
    WHERE s <> ''
    AND userid <> postuser) as a
GROUP BY a.s;
# (4)
SELECT s, count(userid) as c 
FROM actionlog.action_visit_member_without_see_himself_2
GROUP BY s;

# (1)
SELECT count(a.userid) as user_count
FROM (
    SELECT userid, count(userid) as c
    FROM actionlog.action_visit_member_without_see_himself_1
    GROUP BY userid) as a;
# (2)
SELECT count(a.userid) as user_count
FROM (
    SELECT userid, count(userid) as c
    FROM actionlog.action_visit_member_without_see_himself_tab_records_1
    GROUP BY userid) as a;
# (3)
SELECT a.s, count(a.userid) as user_count
FROM (
    SELECT userid, s, count(userid) as a
    FROM actionlog.action_forumdetail_edited_4
    WHERE s <> ''
    AND userid <> postuser
    GROUP BY userid, s) as a
GROUP BY a.s;
# (4)
SELECT a.s, count(a.userid) as user_count
FROM (
    SELECT s, userid, count(userid) as c 
    FROM actionlog.action_visit_member_without_see_himself_2
    GROUP BY s, userid) as a
GROUP BY a.s;



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

SELECT a.CREATE_FROM, a.m, sum(a.price) as total_redeem
FROM (
    SELECT userid, name, substr(CREATEon,1,7) as m, price, CREATE_FROM 
    FROM plsport_playsport.order_data
    WHERE payway in (1,2,3,4,5,6,9,10) AND sellconfirm = 1
    AND CREATEon between '2013-01-01 00:00:00' AND '2014-12-31 23:59:59'
    ORDER BY CREATEon DESC) as a
GROUP BY a.CREATE_FROM, a.m ;

SELECT a.CREATE_FROM, a.m, count(a.price) as total_redeem_count
FROM (
    SELECT userid, name, substr(CREATEon,1,7) as m, price, CREATE_FROM 
    FROM plsport_playsport.order_data
    WHERE payway in (1,2,3,4,5,6,9,10) AND sellconfirm = 1
    AND CREATEon between '2013-01-01 00:00:00' AND '2014-12-31 23:59:59'
    ORDER BY CREATEon DESC) as a
GROUP BY a.CREATE_FROM, a.m ;


# 誰有用過快速儲值噱幣

SELECT count(b.userid) as c
FROM (
    SELECT a.userid, a.name, count(a.userid) as c
    FROM (
        SELECT userid, name, substr(CREATEon,1,7) as m, price, CREATE_FROM 
        FROM plsport_playsport.order_data
        WHERE payway in (1,2,3,4,5,6,9,10) AND sellconfirm = 1
        AND CREATEon between '2014-04-01 00:00:00' AND '2014-04-30 23:59:59'
        AND CREATE_FROM = 3
        ORDER BY CREATEon DESC) as a
    GROUP BY a.userid) as b;



# -----------------------------------------------
# 2014-6-27 數據補充
#     (1)快速結帳的轉換率
#     (2)使用儲值優惠的下一筆儲值金額
#
# note: 快速結帳的記錄表是quick_order_bonus_today
# -----------------------------------------------


SELECT a.m, count(a.userid) as c
FROM (
    SELECT userid, bonus_for_price, CREATE_time, substr(CREATE_time,1,7) as m, order_data_id
    FROM plsport_playsport.quick_order_bonus_today
    ORDER BY CREATE_time DESC) as a
GROUP BY a.m;

SELECT a.m, count(a.userid) as c
FROM (
    SELECT userid, bonus_for_price, CREATE_time, substr(CREATE_time,1,7) as m, order_data_id
    FROM plsport_playsport.quick_order_bonus_today
    WHERE order_data_id is not null
    ORDER BY CREATE_time DESC) as a
GROUP BY a.m;


SELECT userid, bonus_for_price, CREATE_time, substr(CREATE_time,1,7) as m, order_data_id
FROM plsport_playsport.quick_order_bonus_today
WHERE order_data_id is not null
ORDER BY CREATE_time DESC;

        CREATE TABLE plsport_playsport._who_accept_fast_checkout_offer engine = myisam
        SELECT userid, order_data_id, (case when (userid is not null) then 'accept_offer' end) as fast_checkout
        FROM plsport_playsport.quick_order_bonus_today
        WHERE order_data_id is not null
        ORDER BY CREATE_time DESC;

        CREATE TABLE plsport_playsport._who_accept_fast_checkout_offer_namelist engine = myisam
        SELECT userid, count(userid) as c 
        FROM plsport_playsport._who_accept_fast_checkout_offer
        GROUP BY userid;




CREATE TABLE plsport_playsport._who_accept_fast_checkout_offer_complete_order_history engine = myisam
SELECT a.id, a.userid, a.name, a.CREATEon, a.ordernumber, a.price, a.sellconfirm, a.payway, a.CREATE_FROM, a.platform_type
FROM plsport_playsport.order_data a inner join plsport_playsport._who_accept_fast_checkout_offer_namelist b on a.userid = b.userid
ORDER BY a.userid;

CREATE TABLE plsport_playsport._who_accept_fast_checkout_offer_complete_order_history_done engine = myisam
SELECT a.id, a.userid, a.name, a.CREATEon, a.ordernumber, a.price, 
       (case when (a.payway = 1) then '信用卡'
             when (a.payway = 2) then 'ATM'
             when (a.payway = 3) then '超商'
             when (a.payway = 4) then '支付寶'
             when (a.payway = 5) then 'Paypal'
             when (a.payway = 6) then 'MyCard' else '有問題' end) as payway,
       (case when (a.CREATE_FROM = 0) then '一般儲值'
             when (a.CREATE_FROM = 1) then '噱幣不足'
             when (a.CREATE_FROM = 2) then '噱幣不足-優惠'
             when (a.CREATE_FROM = 3) then '快速結帳'
             when (a.CREATE_FROM = 4) then '快速結帳-優惠'
             when (a.CREATE_FROM = 5) then '手機'
             when (a.CREATE_FROM = 6) then '推廌999'
             when (a.CREATE_FROM = 7) then '新手優化路徑'
             when (a.CREATE_FROM = 8) then '行銷活動' end) as CREATE_FROM,
       (case when (a.platform_type = 1) then '電腦'
             when (a.platform_type = 2) then '手機'
             when (a.platform_type = 3) then '平板' end ) as platform,
       (case when (a.sellconfirm = 1) then '' else '沒繳費' end) as sellconfirm, b.fast_checkout
FROM plsport_playsport._who_accept_fast_checkout_offer_complete_order_history a 
     LEFT JOIN plsport_playsport._who_accept_fast_checkout_offer b on a.id = b.order_data_id
ORDER BY a.userid, a.CREATEon;


# =================================================================================================
# 任務: [201405-A-7] 購買預測APP - 測試名單(阿達) 2014-06-20
# http://pm.playsport.cc/index.php/tasksComments?tasksId=3062&projectId=11
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

# 2. MVP測試名單  (阿達) 2015-02-06 新增
# http://pm.playsport.cc/index.php/tasksComments?tasksId=3062&projectId=11
# 時間：2/9(一)
# 條件：
# a. 近三個月有消費的使用者
# b. 使用手機比率超過 60%
# c. 有在使用購牌專區購牌
# 欄位：暱稱、ID、總儲值金額、近三個月儲值金額、購牌專區消費金額、居住地、最近登入時間

# 2015-03-02 15:59
# Eddy [行銷企劃]
# eddy@playsport.cc

# to Eddy：
# 煩請3/31再產生一次 MVP測試名單
# 謝謝！
#     任務狀態: 進行中

# To Eddy：2015-04-11 16:27
# 
# 麻煩再重跑一次MVP測試名單，條件修正如下：
# 條件：
# a. 近一個月有消費的使用者
# b. 使用手機比率超過 60%
# c. 近一個月"購牌專區消費金額、購買後推薦專區消費金額、頭三標消費金額、首頁消費金額"總金額超過 1500元
# 
# 可以的話，希望於 4/15(三)中午前完成名單
#     任務狀態: 重新開啟


CREATE TABLE actionlog.action_201501_platform engine = myisam
SELECT userid, platform_type FROM actionlog.action_201501 WHERE userid <> '';
CREATE TABLE actionlog.action_201502_platform engine = myisam
SELECT userid, platform_type FROM actionlog.action_201502 WHERE userid <> '';
CREATE TABLE actionlog.action_201503_platform engine = myisam
SELECT userid, platform_type FROM actionlog.action_201503 WHERE userid <> '';
CREATE TABLE actionlog.action_201504_platform engine = myisam
SELECT userid, platform_type FROM actionlog.action_201504 WHERE userid <> '';

CREATE TABLE actionlog.action_201501_platform_group engine = myisam
SELECT userid, platform_type, count(userid) as c FROM actionlog.action_201501_platform GROUP BY userid, platform_type;
CREATE TABLE actionlog.action_201502_platform_group engine = myisam
SELECT userid, platform_type, count(userid) as c FROM actionlog.action_201502_platform GROUP BY userid, platform_type;
CREATE TABLE actionlog.action_201503_platform_group engine = myisam
SELECT userid, platform_type, count(userid) as c FROM actionlog.action_201503_platform GROUP BY userid, platform_type;
CREATE TABLE actionlog.action_201504_platform_group engine = myisam
SELECT userid, platform_type, count(userid) as c FROM actionlog.action_201504_platform GROUP BY userid, platform_type;


        CREATE TABLE actionlog.action_platform_group engine = myisam SELECT * FROM actionlog.action_201501_platform_group;
        INSERT IGNORE INTO actionlog.action_platform_group SELECT * FROM actionlog.action_201502_platform_group;
        INSERT IGNORE INTO actionlog.action_platform_group SELECT * FROM actionlog.action_201503_platform_group;
        INSERT IGNORE INTO actionlog.action_platform_group SELECT * FROM actionlog.action_201504_platform_group;        

        # 桌上/手機/平板 等平台登入的pv計算
        CREATE TABLE actionlog._actionlog_platform_visit engine = myisam
        SELECT d.userid, d.desktop, d.mobile, d.TABLEt, round(d.desktop/d.total,3) as desktop_p, round(d.mobile/d.total,3) as mobile_p, round(d.TABLEt/d.total,3) as TABLEt_p
        FROM (
            SELECT c.userid, c.desktop, c.mobile, c.TABLEt, (c.desktop+c.mobile+c.TABLEt) as total
            FROM (
                SELECT b.userid, sum(b.desktop) as desktop, sum(b.mobile) as mobile, sum(b.TABLEt) as TABLEt
                FROM (
                    SELECT a.userid, 
                           (case when (a.platform_type = 1) then c else 0 end) as desktop, #桌上
                           (case when (a.platform_type = 2) then c else 0 end) as mobile,  #手機
                           (case when (a.platform_type = 3) then c else 0 end) as TABLEt   #平板
                    FROM (
                        SELECT userid, platform_type, sum(c) as c
                        FROM actionlog.action_platform_group
                        GROUP BY userid, platform_type
                        ORDER BY userid) as a) as b
                GROUP BY b.userid) as c) as d;

drop TABLE actionlog.action_201412_platform, actionlog.action_201412_platform_group;
drop TABLE actionlog.action_201501_platform, actionlog.action_201501_platform_group;
drop TABLE actionlog.action_201502_platform, actionlog.action_201502_platform_group;
drop TABLE actionlog.action_201503_platform, actionlog.action_201503_platform_group;

use plsport_playsport;
        #2選1
        #(1)使用分群資料
        CREATE TABLE plsport_playsport._list_1 engine = myisam
        SELECT a.userid, b.nickname, date(b.CREATEon) as join_date, a.g as cluster
        FROM user_cluster.cluster_with_real_userid a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;
        #(2)不用分群資料
        CREATE TABLE plsport_playsport._list_1 engine = myisam
        SELECT userid, nickname, date(CREATEon) as join_date
        FROM plsport_playsport.member;

        # 最近一次的登入時間
        CREATE TABLE plsport_playsport._last_login_time engine = myisam
        SELECT userid, max(signin_time) as last_login
        FROM plsport_playsport.member_signin_log_archive
        GROUP BY userid;

        ALTER TABLE `_last_login_time` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE plsport_playsport._list_1 ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._last_login_time ADD INDEX (`userid`);

CREATE TABLE plsport_playsport._list_2 engine = myisam
SELECT a.userid, a.nickname, a.join_date, date(b.last_login) as last_login
FROM plsport_playsport._list_1 a LEFT JOIN plsport_playsport._last_login_time b on a.userid = b.userid;

        # 開站以來總儲值金額
        CREATE TABLE plsport_playsport._total_redeem engine = myisam
        SELECT userid, sum(price) as total_redeem 
        FROM plsport_playsport.order_data
        WHERE payway in (1,2,3,4,5,6,9,10) AND sellconfirm = 1
        GROUP BY userid;

        # 近3個月的儲值金額
        CREATE TABLE plsport_playsport._total_redeem_in_three_month engine = myisam
        SELECT userid, sum(price) as redeem_3_months
        FROM plsport_playsport.order_data
        WHERE payway in (1,2,3,4,5,6,9,10) AND sellconfirm = 1
        AND CREATEon between subdate(now(),35) AND now() #近3個月
        GROUP BY userid;

        ALTER TABLE  `_total_redeem` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
        ALTER TABLE  `_total_redeem_in_three_month` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

        ALTER TABLE plsport_playsport._list_2 ADD INDEX (`userid`);  
        ALTER TABLE plsport_playsport._total_redeem ADD INDEX (`userid`); 
        ALTER TABLE plsport_playsport._total_redeem_in_three_month ADD INDEX (`userid`);  

CREATE TABLE plsport_playsport._list_3 engine = myisam
SELECT c.userid, c.nickname, c.join_date, c.last_login, c.total_redeem, d.redeem_3_months
FROM (
    SELECT a.userid, a.nickname, a.join_date, a.last_login, b.total_redeem
    FROM plsport_playsport._list_2 a LEFT JOIN plsport_playsport._total_redeem b on a.userid = b.userid) as c
    LEFT JOIN plsport_playsport._total_redeem_in_three_month as d on c.userid = d.userid;

        drop TABLE if exists plsport_playsport._predict_buyer;
        drop TABLE if exists plsport_playsport._predict_buyer_with_cons;

        #此段SQL是計算各購牌位置記錄的金額
        #先predict_buyer + predict_buyer_cons_split
        
        ALTER TABLE plsport_playsport.predict_buyer ADD INDEX (`id`);  
        ALTER TABLE plsport_playsport.predict_buyer_cons_split ADD INDEX (`id_predict_buyer`);  
        
        CREATE TABLE plsport_playsport._predict_buyer engine = myisam
        SELECT a.id, a.buyerid, a.id_bought, a.buy_date , a.buy_price, b.position, b.cons, b.allianceid
        FROM plsport_playsport.predict_buyer a LEFT JOIN plsport_playsport.predict_buyer_cons_split b on a.id = b.id_predict_buyer
        WHERE a.buy_price <> 0
        AND a.buy_date between '2014-03-04 00:00:00' AND '2016-12-31 23:59:59'; #2014/03/04是開始有購牌追蹤代碼的日子

        ALTER TABLE plsport_playsport._predict_buyer ADD INDEX (`id_bought`);  
        ALTER TABLE plsport_playsport.predict_seller ADD INDEX (`id`);  
        ALTER TABLE plsport_playsport._predict_buyer convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE plsport_playsport.predict_seller convert to character set utf8 collate utf8_general_ci;
        
        #再join predict_seller
        CREATE TABLE plsport_playsport._predict_buyer_with_cons engine = myisam
        SELECT c.id, c.buyerid, c.id_bought, d.sellerid ,c.buy_date , c.buy_price, c.position, c.cons, c.allianceid
        FROM plsport_playsport._predict_buyer c LEFT JOIN plsport_playsport.predict_seller d on c.id_bought = d.id;

        #計算各購牌位置記錄的金額
        CREATE TABLE plsport_playsport._buy_position engine = myisam
        SELECT d.buyerid, d.BRC, d.BZ, d.FRND, d.FR, d.WPB, d.MPB, d.IDX, d.HT, d.US, d.NONE, 
               (d.BRC+d.BZ+d.FRND+d.FR+d.WPB+d.MPB+d.IDX+d.HT+d.US+d.NONE) as total #把所有的金額加起來
        FROM (
                SELECT c.buyerid, sum(c.BRC) as BRC, sum(c.BZ) as BZ, sum(c.FRND) as FRND, sum(c.FR) as FR, 
                                  sum(c.WPB) as WPB, sum(c.MPB) as MPB, sum(c.IDX) as IDX, sum(c.HT) as HT,
                                  sum(c.US) as US, sum(c.NONE) as NONE
                FROM (
                        SELECT b.buyerid, 
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
                        FROM (
                                SELECT a.buyerid, a.p, sum(a.buy_price) as spent
                                FROM (
                                    SELECT buyerid, buy_date, buy_price,  
                                               (case when (substr(position,1,3) = 'BRC')  then 'BRC' #購買後推專
                                                     when (substr(position,1,2) = 'BZ')   then 'BZ'  #購牌專區
                                                     when (substr(position,1,4) = 'FRND') then 'FRND'#明燈
                                                     when (substr(position,1,2) = 'FR')   then 'FR'  #討論區
                                                     when (substr(position,1,3) = 'WPB')  then 'WPB' #勝率榜
                                                     when (substr(position,1,3) = 'MPB')  then 'MPB' #主推榜
                                                     when (substr(position,1,3) = 'IDX')  then 'IDX' #首頁
                                                     when (substr(position,1,2) = 'HT')   then 'HT'  #頭三標
                                                     when (substr(position,1,2) = 'US')   then 'US'  #玩家搜尋
                                                     when (position is null)              then 'NONE' else 'PROBLEM' end) as p 
                                    FROM plsport_playsport._predict_buyer_with_cons
                                    WHERE buy_date between subdate(now(),35) AND now()) as a
                                GROUP BY a.buyerid, a.p) as b) as c
                GROUP BY c.buyerid) as d;
                
        ALTER TABLE  `_buy_position` CHANGE  `buyerid`  `buyerid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT  '購買者userid';
        ALTER TABLE plsport_playsport._list_3 ADD INDEX (`userid`);  
        ALTER TABLE plsport_playsport._buy_position ADD INDEX (`buyerid`); 

CREATE TABLE plsport_playsport._list_4 engine = myisam
SELECT a.userid, a.nickname, a.join_date, a.last_login, a.total_redeem, a.redeem_3_months,
       b.BRC, b.BZ, b.FRND, b.FR, b.WPB, b.MPB, b.IDX, b.HT, b.US, b.NONE, b.total
FROM plsport_playsport._list_3 a LEFT JOIN plsport_playsport._buy_position b on a.userid = b.buyerid;


        # 2015-04-11 16:27 新任務製作分岐 http://pm.playsport.cc/index.php/tasksComments?tasksId=3062&projectId=11
        CREATE TABLE plsport_playsport._list_5 engine = myisam
        SELECT * FROM plsport_playsport._list_4
        where total is not null;

        CREATE TABLE plsport_playsport._devices engine = myisam
        SELECT userid, desktop_p, (mobile_p+tablet_p) as mobile_p
        FROM actionlog._actionlog_platform_visit;

                ALTER TABLE plsport_playsport._list_5 ADD INDEX (`userid`); 
                ALTER TABLE plsport_playsport._devices ADD INDEX (`userid`); 
                ALTER TABLE plsport_playsport._list_5 convert to character set utf8 collate utf8_general_ci;
                ALTER TABLE plsport_playsport._devices convert to character set utf8 collate utf8_general_ci;
                        
        CREATE TABLE plsport_playsport._list_6 engine = myisam
        SELECT a.userid, a.nickname, a.join_date, a.last_login, a.total_redeem, a.redeem_3_months,
               a.BRC, a.BZ, a.FRND, a.FR, a.WPB, a.MPB, a.IDX, a.HT, a.US, a.NONE, a.total, b.desktop_p, b.mobile_p
        FROM plsport_playsport._list_5 a LEFT JOIN plsport_playsport._devices b on a.userid = b.userid;

                ALTER TABLE plsport_playsport._list_6 ADD INDEX (`userid`); 
                ALTER TABLE plsport_playsport._user_city ADD INDEX (`userid`); 
                ALTER TABLE plsport_playsport._list_6 convert to character set utf8 collate utf8_general_ci;
                ALTER TABLE plsport_playsport._user_city convert to character set utf8 collate utf8_general_ci;


        CREATE TABLE plsport_playsport._list_7 engine = myisam
        SELECT a.userid, a.nickname, a.join_date, a.last_login, a.total_redeem, a.redeem_3_months,
               a.BRC, a.BZ, a.FRND, a.FR, a.WPB, a.MPB, a.IDX, a.HT, a.US, a.NONE, a.total, a.desktop_p, a.mobile_p, b.city
        FROM plsport_playsport._list_6 a LEFT JOIN plsport_playsport._user_city b on a.userid = b.userid;


        CREATE TABLE plsport_playsport._list_8 engine = myisam
        SELECT userid, nickname, total_redeem, total, BRC, BZ, HT, IDX, desktop_p, mobile_p, city, last_login
        FROM plsport_playsport._list_7
        where (BRC+BZ+HT+IDX) > 1499
        and mobile_p > 0.59;







#以下是原本的任務............................................................................................
        # (1)計算玩家搜尋的pv
        CREATE TABLE actionlog.action_usersearch engine = myisam
        SELECT userid, uri, time FROM actionlog.action_201412 WHERE uri LIKE '%usersearch.php%' AND userid <> '';
        INSERT IGNORE INTO actionlog.action_usersearch SELECT userid, uri, time FROM actionlog.action_201501 WHERE uri LIKE '%usersearch.php%' AND userid <> '';
        INSERT IGNORE INTO actionlog.action_usersearch SELECT userid, uri, time FROM actionlog.action_201502 WHERE uri LIKE '%usersearch.php%' AND userid <> '';
        INSERT IGNORE INTO actionlog.action_usersearch SELECT userid, uri, time FROM actionlog.action_201503 WHERE uri LIKE '%usersearch.php%' AND userid <> '';

        CREATE TABLE plsport_playsport._usersearch_count engine = myisam
        SELECT userid, count(userid) as us_pv
        FROM actionlog.action_usersearch
        GROUP BY userid;

        # (2)計算購牌專區的pv - 2014-06-24補充
        CREATE TABLE actionlog.action_buypredict engine = myisam
        SELECT userid, uri, time FROM actionlog.action_201412 WHERE uri LIKE '%buy_predict.php%' AND userid <> '';
        INSERT IGNORE INTO actionlog.action_buypredict SELECT userid, uri, time FROM actionlog.action_201501 WHERE uri LIKE '%buy_predict.php%' AND userid <> '';
        INSERT IGNORE INTO actionlog.action_buypredict SELECT userid, uri, time FROM actionlog.action_201502 WHERE uri LIKE '%buy_predict.php%' AND userid <> '';
        INSERT IGNORE INTO actionlog.action_buypredict SELECT userid, uri, time FROM actionlog.action_201503 WHERE uri LIKE '%buy_predict.php%' AND userid <> '';

        CREATE TABLE plsport_playsport._buypredict_count engine = myisam
        SELECT userid, count(userid) as bp_pv
        FROM actionlog.action_buypredict
        GROUP BY userid;

        ALTER TABLE plsport_playsport._list_4 ADD INDEX (`userid`);  
        ALTER TABLE plsport_playsport._usersearch_count ADD INDEX (`userid`); 
        ALTER TABLE plsport_playsport._buypredict_count ADD INDEX (`userid`); 
        ALTER TABLE plsport_playsport._usersearch_count convert to character SET utf8 collate utf8_general_ci;
        ALTER TABLE plsport_playsport._buypredict_count convert to character SET utf8 collate utf8_general_ci;

CREATE TABLE plsport_playsport._list_5 engine = myisam
SELECT c.userid, c.nickname, c.join_date, c.last_login, c.total_redeem, c.redeem_3_months,
       c.BRC, c.BZ, c.FRND, c.FR, c.WPB, c.MPB, c.IDX, c.HT, c.US, c.NONE, c.total, c.us_pv, d.bp_pv
FROM (
        SELECT a.userid, a.nickname, a.join_date, a.last_login, a.total_redeem, a.redeem_3_months,
               a.BRC, a.BZ, a.FRND, a.FR, a.WPB, a.MPB, a.IDX, a.HT, a.US, a.NONE, a.total, b.us_pv
        FROM plsport_playsport._list_4 a LEFT JOIN plsport_playsport._usersearch_count b on a.userid = b.userid) as c
        LEFT JOIN plsport_playsport._buypredict_count as d on c.userid = d.userid;

        # ========================================
        # 可以直接用之前寫的居住地查詢, 往上找就有
        # 產生_city_info_ok_with_chinese
        # 搜尋keyword "地址"
        # line: 1536
        # update: 201-03-30 已經寫了新的居住地
        # 執行step16_user_city.py即可
        # ========================================
        ALTER TABLE  `_user_city` CHANGE  `userid`  `userid` VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

        ALTER TABLE plsport_playsport._list_5 ADD INDEX (`userid`);  
        ALTER TABLE plsport_playsport._user_city ADD INDEX (`userid`);  

CREATE TABLE plsport_playsport._list_6 engine = myisam
SELECT a.userid, a.nickname, a.join_date, a.last_login, a.total_redeem, a.redeem_3_months,
       a.BRC, a.BZ, a.FRND, a.FR, a.WPB, a.MPB, a.IDX, a.HT, a.US, a.NONE, a.total, a.us_pv, a.bp_pv, b.city
FROM plsport_playsport._list_5 a LEFT JOIN plsport_playsport._user_city b on a.userid = b.userid;

        ALTER TABLE plsport_playsport._list_6 ADD INDEX (`userid`);  
        ALTER TABLE actionlog._actionlog_platform_visit ADD INDEX (`userid`); 
        ALTER TABLE plsport_playsport._list_6 convert to character SET utf8 collate utf8_general_ci;        
        ALTER TABLE actionlog._actionlog_platform_visit convert to character SET utf8 collate utf8_general_ci;       

CREATE TABLE plsport_playsport._list_7 engine = myisam
SELECT a.userid, a.nickname, a.join_date, a.last_login, a.total_redeem, a.redeem_3_months,
       a.BRC, a.BZ, a.FRND, a.FR, a.WPB, a.MPB, a.IDX, a.HT, a.US, a.NONE, a.total, a.us_pv, a.bp_pv, a.city,
       b.desktop, b.mobile, b.TABLEt, b.desktop_p, b.mobile_p, b.TABLEt_p 
FROM plsport_playsport._list_6 a LEFT JOIN actionlog._actionlog_platform_visit b on a.userid = b.userid;

        ALTER TABLE  `_list_7` CHANGE  `nickname`  `nickname` CHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ;

# a. 近三個月有消費的使用者
# b. 使用手機比率超過 60%
# c. 有在使用購牌專區購牌
# 欄位：暱稱、ID、總儲值金額、近三個月儲值金額、購牌專區消費金額、居住地、最近登入時間

CREATE TABLE plsport_playsport._list_7_ok engine = myisam
SELECT userid, nickname, last_login, total_redeem, redeem_3_months, BZ, BRC, HT, IDX, city, desktop_p, (mobile_p+TABLEt_p) as mobile_p
FROM plsport_playsport._list_7
WHERE redeem_3_months > 0       #a. 近三個月有消費的使用者
AND (BZ+BRC+HT+IDX) > 0      #c. 有在使用購牌專區購牌
AND (mobile_p+TABLEt_p) > 0.59; #b. 使用手機比率超過 60%


SELECT 'userid', 'nickname', '最後登入', '總儲值金額', '近三個月儲值金額', '購牌專區$', '購買後推薦專區$', '頭三標$', '首頁$', '居住地','使用電腦比例','使用手機比例' UNION (
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_list_7_ok.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._list_7_ok);




#--------------------------------------------------------------------------------------------------------------------

CREATE TABLE plsport_playsport._pcash_log engine = myisam
SELECT userid, amount, date 
FROM plsport_playsport.pcash_log
WHERE payed = 1 AND type = 1;

# 在3天內有消費的使用者
CREATE TABLE plsport_playsport._who_have_spent_in_three_day engine = myisam
SELECT userid, sum(amount) as spent_in_3_days
FROM plsport_playsport._pcash_log
WHERE date between subdate(now(),4) AND now()
GROUP BY userid;

        ALTER TABLE plsport_playsport._list_7 ADD INDEX (`userid`);  
        ALTER TABLE plsport_playsport._who_have_spent_in_three_day ADD INDEX (`userid`); 

CREATE TABLE plsport_playsport._list_8 engine = myisam
SELECT a.userid, a.nickname, a.join_date, a.last_login, a.total_redeem, a.redeem_3_months,
       a.BRC, a.BZ, a.FRND, a.FR, a.WPB, a.MPB, a.IDX, a.HT, a.US, a.NONE, a.total, a.us_pv, a.bp_pv, a.city1,
       a.desktop, a.mobile, a.TABLEt, a.desktop_p, a.mobile_p, a.TABLEt_p, b.spent_in_3_days
FROM plsport_playsport._list_7 a LEFT JOIN plsport_playsport._who_have_spent_in_three_day b on a.userid = b.userid;

# 結束
CREATE TABLE plsport_playsport._list_9 engine = myisam
SELECT * FROM plsport_playsport._list_8
WHERE redeem_3_months is not null;

# ------------------------------
# 補充購買合牌的資訊
# ------------------------------

CREATE TABLE plsport_playsport._buy_match_prediction engine = myisam
SELECT a.userid, sum(a.amount) as buy_match_predcition
FROM (
    SELECT userid, amount, date 
    FROM plsport_playsport.pcash_log
    WHERE payed = 1 AND type in (7,9)) as a
GROUP BY a.userid;

# ------------------------------
# 有在使用觀看預測比例的人
# ------------------------------
        # (2)計算購牌專區的pv - 2014-06-24補充
        CREATE TABLE actionlog.action_predict_game engine = myisam
        SELECT userid, uri, time FROM actionlog.action_201404 WHERE uri LIKE '%action=scale%' AND userid <> '';

        INSERT IGNORE INTO actionlog.action_predict_game SELECT userid, uri, time FROM actionlog.action_201405 WHERE uri LIKE '%action=scale%' AND userid <> '';
        INSERT IGNORE INTO actionlog.action_predict_game SELECT userid, uri, time FROM actionlog.action_201406 WHERE uri LIKE '%action=scale%' AND userid <> '';
        INSERT IGNORE INTO actionlog.action_predict_game SELECT userid, uri, time FROM actionlog.action_201407 WHERE uri LIKE '%action=scale%' AND userid <> '';

        CREATE TABLE plsport_playsport._predict_game_count engine = myisam
        SELECT userid, count(userid) as predict_game_pv
        FROM actionlog.action_predict_game
        GROUP BY userid;

        ALTER TABLE plsport_playsport._list_9 ADD INDEX (`userid`);  
        ALTER TABLE plsport_playsport._predict_game_count ADD INDEX (`userid`); 
        ALTER TABLE plsport_playsport._buy_match_prediction ADD INDEX (`userid`); 

CREATE TABLE plsport_playsport._list_10 engine = myisam
SELECT a.userid, a.nickname, a.join_date, a.last_login, a.total_redeem, a.redeem_3_months,
       a.BRC, a.BZ, a.FRND, a.FR, a.WPB, a.MPB, a.IDX, a.HT, a.US, a.NONE, a.total, a.us_pv, a.bp_pv, a.city1,
       a.desktop, a.mobile, a.TABLEt, a.desktop_p, a.mobile_p, a.TABLEt_p, a.spent_in_3_days,
       b.buy_match_predcition
FROM plsport_playsport._list_9 a LEFT JOIN plsport_playsport._buy_match_prediction b on a.userid = b.userid;

        ALTER TABLE plsport_playsport._list_10 ADD INDEX (`userid`);  

CREATE TABLE plsport_playsport._list_11 engine = myisam
SELECT a.userid, a.nickname, a.join_date, a.last_login, a.total_redeem, a.redeem_3_months,
       a.BRC, a.BZ, a.FRND, a.FR, a.WPB, a.MPB, a.IDX, a.HT, a.US, a.NONE, a.total, a.us_pv, a.bp_pv, a.city1,
       a.desktop, a.mobile, a.TABLEt, a.desktop_p, a.mobile_p, a.TABLEt_p, a.spent_in_3_days,
       a.buy_match_predcition, b.predict_game_pv
FROM plsport_playsport._list_10 a LEFT JOIN plsport_playsport._predict_game_count b on a.userid = b.userid;




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
CREATE TABLE plsport_playsport._who_is_FROM_new_user_path engine = myisam
SELECT userid, name, date(CREATEon) as pay_date, price, payway, platform_type
FROM plsport_playsport.order_data
WHERE CREATE_FROM = 7 #產生的訂單是從新使用者買牌路徑過來的
AND sellconfirm = 1
ORDER BY CREATEon DESC;

ALTER TABLE  `_who_is_FROM_new_user_path` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

# 這些人的加入會員時間點
CREATE TABLE plsport_playsport._who_is_FROM_new_user_path_1 engine = myisam
SELECT a.userid, a.name, a.pay_date, date(b.CREATEon) as join_date, a.price, a.payway, a.platform_type
FROM plsport_playsport._who_is_FROM_new_user_path a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

# 每一個人曾經儲值過多少錢?
CREATE TABLE plsport_playsport._total_redeem_every_one engine = myisam
SELECT a.userid, sum(a.price) as total_redeem
FROM (
    SELECT userid, price 
    FROM plsport_playsport.order_data
    WHERE sellconfirm = 1
    AND CREATE_FROM in (0,1,2,3,4,5,6) # 記得要把0算進去
    AND payway in (1,2,3,4,5,6,9,10)) as a
GROUP BY a.userid;

ALTER TABLE  `_total_redeem_every_one` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

# 從新使用者買牌路徑過來的人,在第一次儲值之後, 有沒有再度儲值?
CREATE TABLE plsport_playsport._who_is_FROM_new_user_path_2 engine = myisam
SELECT a.userid, a.name, a.pay_date, a.join_date, a.price, a.payway, a.platform_type, b.total_redeem
FROM plsport_playsport._who_is_FROM_new_user_path_1 a LEFT JOIN plsport_playsport._total_redeem_every_one b on a.userid = b.userid;


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
CREATE TABLE plsport_playsport._redeem_ranking_1 engine = myisam
SELECT b.userid, b.nickname, a.name, date(b.CREATEon) as join_date, a.redeem
FROM ( 
    SELECT userid, name, sum(price) as redeem 
    FROM plsport_playsport.order_data
    WHERE sellconfirm = 1
    GROUP BY userid) as a LEFT JOIN plsport_playsport.member b on a.userid = b.userid
ORDER BY a.redeem DESC;


        # 最近一次的登入時間
        CREATE TABLE plsport_playsport._last_login_time engine = myisam
        SELECT userid, max(signin_time) as last_login
        FROM plsport_playsport.member_signin_log_archive
        GROUP BY userid;

        ALTER TABLE plsport_playsport._redeem_ranking_1 ADD INDEX (`userid`); 
        ALTER TABLE plsport_playsport._last_login_time ADD INDEX (`userid`);

# 歷史儲值金額排名 + 最近一次的登入時間
CREATE TABLE plsport_playsport._redeem_ranking_2 engine = myisam
SELECT a.userid, a.nickname, a.name, a.join_date, a.redeem, date(b.last_login) as last_login
FROM plsport_playsport._redeem_ranking_1 a LEFT JOIN plsport_playsport._last_login_time b on a.userid = b.userid
WHERE b.last_login is not null;

# 最後名單, 用貼上的就好
SELECT a.userid, a.nickname, a.name, a.join_date, a.redeem, a.last_login, a.recent_login_day
FROM (
    SELECT userid, nickname, name, join_date, redeem, last_login, datediff(now(), last_login) as recent_login_day
    FROM plsport_playsport._redeem_ranking_2) as a
WHERE a.recent_login_day < 10 # 要近10天內登入的人
ORDER BY a.redeem DESC
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
# 標題                    代碼 post_FROM=
# 討論區列表分析王區塊    FLA
# 討論區內頁分析王區塊    FDA
# 更多分析王列表          AL
# =================================================================================================

# 先撈出6月27日~7月13日的post_FROM=的所有LOG
CREATE TABLE actionlog.action_201406_post_FROM engine = myisam
SELECT userid, uri, time FROM actionlog.action_201406 WHERE userid <> '' AND uri LIKE '%post_FROM=%';
CREATE TABLE actionlog.action_201407_post_FROM engine = myisam
SELECT userid, uri, time FROM actionlog.action_201407 WHERE userid <> '' AND uri LIKE '%post_FROM=%';

        # 再把6月20日~7月13日的文章內頁log合併成一個檔
        CREATE TABLE actionlog.action_post_FROM engine = myisam SELECT * FROM actionlog.action_201406_post_FROM
        WHERE time between '2014-06-27 00:00:00' AND '2014-06-30 23:59:59';
        INSERT IGNORE INTO actionlog.action_post_FROM SELECT * FROM actionlog.action_201407_post_FROM;

# 接下來的步驟就是在解析uri, 把uri中的變數一個個分出來
# 分出post_FROM
    CREATE TABLE actionlog.action_post_FROM_1 engine = myisam
    SELECT userid, uri, substr(uri,locate('post_FROM=',uri)+10) as u, time
    FROM actionlog.action_post_FROM;


# -----------------------------------------------------------

/*找出6月1日到7月13日之間的最讚分析文*/
CREATE TABLE plsport_playsport._analysis_king engine = myisam 
SELECT userid, subjectid, got_time, gamedate, 
       (case when (subjectid is not null) then 'y' end) as isanalysispost
FROM plsport_playsport.analysis_king
WHERE got_time between '2011-06-12 00:00:00' AND '2014-07-13 23:59:59'
ORDER BY got_time DESC;

# 期間內最讚分析分 + 閱覽數viewtimes
CREATE TABLE plsport_playsport._analysis_king_viewtimes engine = myisam
SELECT a.userid, a.subjectid, a.got_time, a.gamedate, a.isanalysispost, b.viewtimes
FROM plsport_playsport._analysis_king a LEFT JOIN plsport_playsport.forum b on a.subjectid = b.subjectid
ORDER BY got_time;

        # 解析subjectid
        CREATE TABLE actionlog._who_see_analysis_king engine = myisam
        SELECT userid, uri, substr(uri,locate('subjectid=',uri)+10) as u, time 
        FROM actionlog.action_forumdetail;
        # 排除"&"之後多餘的字串
        CREATE TABLE actionlog._who_see_analysis_king_1 engine = myisam
        SELECT userid, uri, 
               (case when (locate('&',u) = 0) then u
                     when (locate('&',u) > 0) then substr(u,1,locate('&',u)-1) end) as subjectid, time
        FROM actionlog._who_see_analysis_king;

        ALTER TABLE actionlog._who_see_analysis_king_1 CHANGE  `subjectid`  `subjectid` VARCHAR( 50 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ;
        ALTER TABLE plsport_playsport._analysis_king CHANGE  `subjectid`  `subjectid` VARCHAR( 30 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
        ALTER TABLE actionlog._who_see_analysis_king_1 ADD INDEX (`subjectid`);
        ALTER TABLE plsport_playsport._analysis_king ADD INDEX (`subjectid`);

# 最讚分析文是被那些users看
CREATE TABLE actionlog._who_see_analysis_king_2 engine = myisam
SELECT a.userid, a.uri, a.subjectid, a.time, b.isanalysispost
FROM actionlog._who_see_analysis_king_1 a LEFT JOIN plsport_playsport._analysis_king b on a.subjectid = b.subjectid
WHERE b.isanalysispost is not null;


        # 要觀察的區間是6/12~6/27和6/28~7/13
        # 計算出最讚分析文的數量, 和總被閱覽數
        # 前-
        SELECT count(subjectid) as subjectid_count, sum(viewtimes) as total_viewtimes 
        FROM plsport_playsport._analysis_king_viewtimes
        WHERE got_time between '2014-06-12 00:00:00' AND '2014-06-27 23:59:59';
        # 後-
        SELECT count(subjectid) as subjectid_count, sum(viewtimes) as total_viewtimes 
        FROM plsport_playsport._analysis_king_viewtimes
        WHERE got_time between '2014-06-28 00:00:00' AND '2014-07-13 23:59:59';

        # 計算出看最讚分析文的人有多少人
        # 前-
        SELECT count(a.userid) as user_count
        FROM (
            SELECT userid, count(subjectid) as c
            FROM actionlog._who_see_analysis_king_2
            WHERE time between '2014-06-12 00:00:00' AND '2014-06-27 23:59:59'
            GROUP BY userid) as a;
        # 後-
        SELECT count(a.userid) as user_count
        FROM (
            SELECT userid, count(subjectid) as c
            FROM actionlog._who_see_analysis_king_2
            WHERE time between '2014-06-28 00:00:00' AND '2014-07-13 23:59:59'
            GROUP BY userid) as a;


# 目的：
# 1. 瞭解點擊分析文瀏覽的來源
# 2. 每篇文章最下方的最讚分析文列表是否有用
# 再請安排追蹤時間、於社群會議上報告時間，謝謝 
#
# 標題                        代碼 post_FROM=
# 討論區列表分析王區塊        FLA
# 討論區文章內頁分析王區塊    FDA (新增)
# 更多分析王列表              AL

CREATE TABLE actionlog.action_201407_post_FROM engine = myisam
SELECT userid, uri, time FROM actionlog.action_201407 WHERE userid <> '' AND uri LIKE '%post_FROM=%';

# 已分成20組, 1~10有看到, 11~20沒看到

CREATE TABLE actionlog.action_201407_post_FROM_1 engine = myisam
SELECT * FROM actionlog.action_201407_post_FROM
WHERE time between '2014-07-22 18:00:00' AND '2014-07-28 23:59:59';

# 接下來的步驟就是在解析uri, 把uri中的變數一個個分出來
# 分出post_FROM
CREATE TABLE actionlog.action_201407_post_FROM_2 engine = myisam
SELECT userid, uri, substr(uri,locate('post_FROM=',uri)+10) as u, time
FROM actionlog.action_201407_post_FROM_1;

        ALTER TABLE actionlog.action_201407_post_FROM_2 ADD INDEX (`userid`);
        ALTER TABLE actionlog.action_201407_post_FROM_2 CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

CREATE TABLE actionlog.action_201407_post_FROM_3 engine = myisam
SELECT (b.id%20)+1 as g, a.userid, a.uri, a.u, a.time 
FROM actionlog.action_201407_post_FROM_2 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

CREATE TABLE actionlog.action_201407_post_FROM_4 engine = myisam
SELECT g, (case when (g<11) then 'A' else 'B' end) as abtest, userid, uri, u, time 
FROM actionlog.action_201407_post_FROM_3;

SELECT abtest, u, count(userid) as c 
FROM actionlog.action_201407_post_FROM_4
GROUP BY abtest, u;

CREATE TABLE actionlog.action_201407_post_FROM_5 engine = myisam
SELECT abtest, userid, u, count(userid) as c
FROM actionlog.action_201407_post_FROM_4
WHERE substr(u,1,3) <> 'VMP'
GROUP BY abtest, userid, u;

SELECT *
FROM (
    SELECT abtest, userid, sum(c) as c 
    FROM actionlog.action_201407_post_FROM_5
    GROUP BY abtest, userid) as a
ORDER BY a.c DESC;


SELECT a.abtest, sum(a.c) as c
FROM (
    SELECT abtest, userid, sum(c) as c 
    FROM actionlog.action_201407_post_FROM_5
    GROUP BY abtest, userid) as a 
GROUP BY a.abtest;


SELECT a.abtest, count(a.userid) as user_count
FROM (
    SELECT abtest, userid, sum(c) as c 
    FROM actionlog.action_201407_post_FROM_5
    GROUP BY abtest, userid) as a
GROUP BY a.abtest;



# 輸出給R, 跑a/b testing檢定
SELECT 'abtest', 'userid', 'u', 'c' UNION(
SELECT * 
INTO outfile 'C:/Users/1-7_ASUS/Desktop/action_201407_post_FROM_5.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog.action_201407_post_FROM_5);


SELECT 'abtest', 'usreid', 'c' UNION (
SELECT abtest, userid, sum(c) as c
INTO outfile 'C:/Users/1-7_ASUS/Desktop/action_201407_post_FROM_6.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog.action_201407_post_FROM_5
GROUP BY abtest, userid);



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
CREATE TABLE actionlog.action_201406_visit_member engine = myisam
SELECT userid, uri, time FROM actionlog.action_201406 WHERE userid <> '' AND uri LIKE '%visit_member.php%';
CREATE TABLE actionlog.action_201407_visit_member engine = myisam
SELECT userid, uri, time FROM actionlog.action_201407 WHERE userid <> '' AND uri LIKE '%visit_member.php%';

        # 再把6月17日~7月13日的個人頁log合併成一個檔
        CREATE TABLE actionlog.action_visit_member engine = myisam SELECT * FROM actionlog.action_201406_visit_member
        WHERE time between '2014-06-17 00:00:00' AND '2014-06-30 23:59:59';
        INSERT IGNORE INTO actionlog.action_visit_member SELECT * FROM actionlog.action_201407_visit_member;

        # -------------------------------------
        # 再來執行code line 2398或搜尋"解析uri"
        # -------------------------------------

        ALTER TABLE actionlog.action_visit_member_edited CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
        ALTER TABLE actionlog.action_visit_member_edited ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport.member ADD INDEX (`userid`);

# 加入分組資訊
CREATE TABLE actionlog.action_visit_member_edited_1 engine = myisam
SELECT (b.id%10)+1 as g, a.userid, a.uri, a.visit, a.action, a.type, a.during, a.vol, a.gameday, a.time
FROM actionlog.action_visit_member_edited a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

# 弄成群組grouped
CREATE TABLE actionlog.action_visit_member_edited_1_grouped engine = myisam
SELECT g, userid, gameday, count(userid) as c 
FROM actionlog.action_visit_member_edited_1
WHERE userid <> visit
GROUP BY g, userid, gameday;

#  組1,2,3總共有多少人?
SELECT count(a.userid) as user_count
FROM (
    SELECT userid, sum(c) as c 
    FROM actionlog.action_visit_member_edited_1_grouped
    WHERE g in (1,2,3)
    GROUP BY userid) as a;

# 組1,2,3有多少人去點新增的按紐(2天前/3天前/4天前)
SELECT count(a.userid) as user_count
FROM (
    SELECT userid, sum(c) as c 
    FROM actionlog.action_visit_member_edited_1_grouped
    WHERE gameday in ("2daysAgo", "3daysAgo", "4daysAgo")
    AND g in (1,2,3)
    GROUP BY userid) as a;

CREATE TABLE plsport_playsport._user_spent_0617_0713 engine = myisam
SELECT c.g, c.userid, sum(c.spent) as total_spent
FROM (
    SELECT (b.id%10)+1 as g, a.userid, a.amount as spent, a.date
    FROM plsport_playsport.pcash_log a LEFT JOIN plsport_playsport.member b on a.userid = b.userid
    WHERE a.date between '2014-06-17 00:00:00' AND '2014-07-13 23:59:59'
    AND a.payed = 1 AND a.type = 1) as c
GROUP BY c.userid;


SELECT g, sum(total_spent) as total_spent
FROM plsport_playsport._user_spent_0617_0713
GROUP BY g;

SELECT g, count(userid) as user_count 
FROM plsport_playsport._user_spent_0617_0713
GROUP BY g;


# 輸出給R, 跑a/b testing檢定
SELECT 'g', 'userid', 'total_spent' UNION(
SELECT * 
INTO outfile 'C:/Users/1-7_ASUS/Desktop/user_spent_0617_0713.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._user_spent_0617_0713);





# =================================================================================================
# to Eddy : (阿達)
# 第二階段優化( 非殺手個人頁顯示購買後推薦專區) A/B testing已上線，再麻煩於 7/25(五)提交報告，謝謝。
# 實驗時間：6/23 ~ 7/21 <<< 記得不要撈錯
# =================================================================================================

# 先看點擊
CREATE TABLE actionlog.action_visit_member_edited_1_recommAND engine = myisam
SELECT a.g, a.userid, a.p, count(a.userid) as c
FROM (
    SELECT g, userid, uri, substr(uri,locate("&rp=",uri)+4,length(uri)) as p, time
    FROM actionlog.action_visit_member_edited_1
    WHERE uri LIKE '%rp=BRC%'
    AND time between '2014-06-23 00:00:00' AND '2014-07-13 23:59:59') as a
GROUP BY a.g, a.userid, a.p;

SELECT g, p, sum(c) as c
FROM actionlog.action_visit_member_edited_1_recommAND
GROUP BY g, p;

# 查閱收益by position
# 因為_predict_buyer_with_cons每天固定都會產生, 所以不用再做了

CREATE TABLE plsport_playsport._predict_buyer_with_cons_1 engine = myisam
SELECT (b.id%10)+1 as g, a.buyerid, a.buy_date, a.buy_price, a.position 
FROM plsport_playsport._predict_buyer_with_cons a LEFT JOIN plsport_playsport.member b on a.buyerid = b.userid
WHERE a.buy_date between '2014-06-23 00:00:00' AND '2014-07-13 23:59:59'
ORDER BY buy_date DESC;

        # 所有位置的各組購買情況
        SELECT g, sum(buy_price) as revenue 
        FROM plsport_playsport._predict_buyer_with_cons_1
        #WHERE substr(position,1,3) = 'BRC'
        GROUP BY g;

        # 購牌專區的各組購買情況
        SELECT g, sum(buy_price) as revenue 
        FROM plsport_playsport._predict_buyer_with_cons_1
        WHERE substr(position,1,3) = 'BRC'
        GROUP BY g;

        SELECT g, position, sum(buy_price) as total_spent
        FROM plsport_playsport._predict_buyer_with_cons_1
        WHERE substr(position,1,3) = 'BRC'
        AND buy_date between '2014-06-23 00:00:00' AND '2014-07-13 23:59:59'
        GROUP BY g, position;

        SELECT g, sum(buy_price) as total_spent 
        FROM plsport_playsport._predict_buyer_with_cons_1
        WHERE buy_date between '2014-06-23 00:00:00' AND '2014-07-13 23:59:59'
        GROUP BY g;


# -------------輸出給R, 跑a/b testing檢定-------------
# 只有BRC購買後推廌專區
SELECT 'g', 'userid', 'v', 'total_spent' UNION(
SELECT a.g, a.buyerid, a.v, sum(a.buy_price) as total_spent
INTO outfile 'C:/Users/1-7_ASUS/Desktop/user_spent_0617_0713_for_recommAND_only_brc.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM (
    SELECT g, buyerid, buy_price, substr(position,6,1) as v 
    FROM plsport_playsport._predict_buyer_with_cons_1
    WHERE substr(position,1,3) = 'BRC'
    AND buy_date between '2014-06-23 00:00:00' AND '2014-07-13 23:59:59') as a
GROUP BY a.buyerid);

# 所有的位置
SELECT 'g', 'userid', 'total_spent' UNION(
SELECT g, buyerid, sum(buy_price) as total_spent 
INTO outfile 'C:/Users/1-7_ASUS/Desktop/user_spent_0617_0713_for_recommAND_all.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._predict_buyer_with_cons_1
WHERE buy_date between '2014-06-23 00:00:00' AND '2014-07-13 23:59:59'
GROUP BY buyerid);


# =================================================================================================
# 任務: 撈取分析文與最讚分析文數量 [新建]  (柔雅) 
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

CREATE TABLE plsport_playsport._1 engine = myisam
SELECT a.m, a.allianceid, count(a.subjectid) as best_ana_post_count
FROM (
    SELECT userid, subjectid, allianceid ,date(got_time) as d, substr(got_time,1,7) as m, year(got_time) as y
    FROM plsport_playsport.analysis_king
    WHERE got_time between '2012-01-01 00:00:00' AND '2014-12-31 23:59:59') as a
GROUP BY a.m, a.allianceid;

CREATE TABLE plsport_playsport._3 engine = myisam
SELECT a.d, a.allianceid, count(a.subjectid) as best_ana_post_count
FROM (
    SELECT userid, subjectid, allianceid, date(got_time) as d, substr(got_time,1,7) as m, year(got_time) as y
    FROM plsport_playsport.analysis_king
    WHERE got_time between '2014-01-01 00:00:00' AND '2014-12-31 23:59:59') as a
GROUP BY a.d, a.allianceid;

CREATE TABLE plsport_playsport._2 engine = myisam
SELECT a.m, a.allianceid, count(a.subjectid) as ana_post_count
FROM (
    SELECT subjectid, posttime, allianceid, date(posttime) as d, substr(posttime,1,7) as m, year(posttime) as y 
    FROM plsport_playsport.forum
    WHERE gametype = 1
    AND posttime between '2012-01-01 00:00:00' AND '2014-12-31 23:59:59'
    ORDER BY posttime) as a
GROUP BY a.m, a.allianceid;

CREATE TABLE plsport_playsport._4 engine = myisam
SELECT a.d, a.allianceid, count(a.subjectid) as ana_post_count
FROM (
    SELECT subjectid, posttime, allianceid, date(posttime) as d, substr(posttime,1,7) as m, year(posttime) as y 
    FROM plsport_playsport.forum
    WHERE gametype = 1
    AND posttime between '2014-01-01 00:00:00' AND '2014-12-31 23:59:59'
    ORDER BY posttime) as a
GROUP BY a.d, a.allianceid;


# =================================================================================================
# 任務: 協助撈取分析文資料 [新建](學文) 2014-11-25 此任務類似上面的
#       本來是柔雅->變學文在負責 2014-12-23
#       http://pm.playsport.cc/index.php/tasksComments?tasksId=3875&projectId=11
# EDDY:
# 麻煩請你提供:
#     1.活動時間內的 NBA 分析文總數
#     2.活動時間內的 NBA 最讚分析文數量
# 
# 煩請撈取以下兩個時間內的資料:
#     1.2014/10/30-11/12(14天)
#     2.2014/11/13-11/26(14天)
#
# 需要的TABLEs:
#     (1) analysis_king
#     (2) forum
# =================================================================================================

# (1)最讚分析文數量
SELECT a.d, a.allianceid, count(a.subjectid) as best_ana_post_count
FROM (
    SELECT userid, subjectid, allianceid, date(got_time) as d, substr(got_time,1,7) as m, year(got_time) as y
    FROM plsport_playsport.analysis_king
    WHERE allianceid = 1 # MLB
    AND got_time between '2015-04-09 00:00:00' AND '2015-04-21 23:59:59') as a
GROUP BY a.d, a.allianceid;

# (2)分析文總數
SELECT a.d, a.allianceid, count(a.subjectid) as ana_post_count
FROM (
    SELECT subjectid, posttime, allianceid, date(posttime) as d, substr(posttime,1,7) as m, year(posttime) as y 
    FROM plsport_playsport.forum
    WHERE gametype = 1 # 分析文
    AND allianceid = 1 # MLB 
    AND posttime between '2015-04-09 00:00:00' AND '2015-04-21 23:59:59'
    ORDER BY posttime) as a
GROUP BY a.d, a.allianceid;

# ------------------------------------------------------------------------------
# to  eddy (學文) 2015-01-16
# http://pm.playsport.cc/index.php/tasksComments?tasksId=3875&projectId=11
# 1/20時會請您撈1/7-1/19這段期間的nba分析文&最讚分析文數量
# 另外要麻煩您順便撈取
#    11/27~12/10(14天)
#    12/11~12/24(14天)
#    12/25~1/7(14天)
#    1/8-1/19(12天)
# 以上這四個區間，看過nba分析文後有使用評分功能的轉換率
# 需求時間：1/20，若您沒時間的話，1/27也可以，謝謝！！.
# 
# 看過nba分析文後有使用評分功能的轉換率定義:
# 條件: 有在討論區中看過nba分析文的人
#        a: 在指定區間內有看過nba分析文的人(排除重覆)
#        b: 在指定區間內有曾為nba分析文評分的人(排除重覆, 只評1篇只+1, 評多篇多日也只+1)
# 看過nba分析文後有使用評分功能的轉換率: b / a
# ------------------------------------------------------------------------------

CREATE TABLE actionlog._forumdetail engine = myisam
SELECT userid, uri, time FROM actionlog.action_201411 
WHERE date(time) between '2014-11-27' AND now() AND userid <> '' AND uri LIKE '%/forumdetail%'; # 限定有登入的人

INSERT IGNORE INTO actionlog._forumdetail
SELECT userid, uri, time FROM actionlog.action_201412 
WHERE date(time) between '2014-11-27' AND now() AND userid <> '' AND uri LIKE '%/forumdetail%';

INSERT IGNORE INTO actionlog._forumdetail
SELECT userid, uri, time FROM actionlog.action_201501
WHERE date(time) between '2014-11-27' AND now() AND userid <> '' AND uri LIKE '%/forumdetail%';

CREATE TABLE actionlog._forumdetail_1 engine = myisam
SELECT b.userid, b.uri, b.time, b.s, (length(b.s)) as ss
FROM (
    SELECT a.userid, a.uri, a.time, substr(a.s,1,locate('&',a.s)-1) as s
    FROM (
        SELECT userid, uri, time, substr(uri,locate('subjectid',uri)+10, length(uri)) as s
        FROM actionlog._forumdetail) as a) as b;

CREATE TABLE actionlog._forumdetail_2 engine = myisam
SELECT userid, uri, time, s as subjectid 
FROM actionlog._forumdetail_1
WHERE ss=15; # 只撈取正確的subjectid, 有很多subjectid都怪怪的, 長度15是標準的

CREATE TABLE actionlog._forumdetail_3 engine = myisam
SELECT userid, date(time) as d, subjectid 
FROM actionlog._forumdetail_2;

        ALTER TABLE actionlog._forumdetail_3 CHANGE `subjectid` `subjectid` VARCHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE actionlog._forumdetail_3 ADD INDEX (`userid`,`d`,`subjectid`);

CREATE TABLE actionlog._forumdetail_4 engine = myisam
SELECT userid, d, subjectid 
FROM actionlog._forumdetail_3
GROUP BY userid, d, subjectid;

# 匯入:
#   (1) forum
#   (2) forum_analysis_score

# (1)NBA的分析文
CREATE TABLE plsport_playsport._nba_analysis_post engine = myisam
SELECT subjectid, subject, posttime, allianceid, date(posttime) as d
FROM plsport_playsport.forum
WHERE gametype = 1 # 分析文
AND allianceid = 3 # NBA 
AND date(posttime) between '2014-11-27' AND now()
ORDER BY posttime DESC;

        ALTER TABLE plsport_playsport._nba_analysis_post ADD INDEX (`subjectid`);

# (2)有看分析文的人 - inner join (1)
CREATE TABLE actionlog._forumdetail_5 engine = myisam
SELECT a.userid, a.d, a.subjectid 
FROM actionlog._forumdetail_4 a inner join plsport_playsport._nba_analysis_post b on a.subjectid = b.subjectid;

        ALTER TABLE plsport_playsport.forum_analysis_score ADD INDEX (`subjectid`);

# (3)有在分析文中評分的人 - inner join (1)
CREATE TABLE plsport_playsport._score_on_nba_analysis_post engine = myisam
SELECT a.subjectid, a.userid, a.score, a.datetime 
FROM plsport_playsport.forum_analysis_score a inner join plsport_playsport._nba_analysis_post b on a.subjectid = b.subjectid;


            # 區間內看分析文的人數
            SELECT count(a.userid)
            FROM (
                SELECT userid, count(userid)
                FROM actionlog._forumdetail_5
                WHERE d between '2014-11-24' AND '2014-12-10'
                GROUP BY userid) as a;

            # 區間內看分析文的人數又有評分的人數
            SELECT count(a.userid)
            FROM (
                SELECT userid, count(userid) 
                FROM plsport_playsport._score_on_nba_analysis_post
                WHERE date(datetime) between '2014-11-24' AND '2014-12-10'
                GROUP BY userid) as a;

# 每日看分析文的人數
SELECT a.d, count(a.userid) as user_count
FROM (
    SELECT d, userid, count(userid) as c 
    FROM actionlog._forumdetail_5
    GROUP BY d, userid) as a
GROUP BY a.d;

# 每日看分析文的人數又有評分的人數
SELECT b.d, count(b.userid) as user_count
FROM (
    SELECT a.d, a.userid, count(a.userid) as c
    FROM (
        SELECT date(datetime) as d, userid, subjectid
        FROM plsport_playsport._score_on_nba_analysis_post) as a
    GROUP BY a.d, a.userid) as b
GROUP BY b.d;



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

CREATE TABLE plsport_playsport._applelist1 engine = myisam
SELECT a.userid, a.sent_text, b.nickname, b.browses, b.CREATEon
FROM plsport_playsport.applelist a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

# 最後一次登入的記錄
CREATE TABLE plsport_playsport._who_last_signin engine = myisam
SELECT a.userid, a.last_sign_in, substr(a.last_sign_in,1,7) as m
FROM (
    SELECT userid, max(signin_time) as last_sign_in 
    FROM plsport_playsport.member_signin_log_archive
    GROUP BY userid
    ORDER BY signin_time DESC) as a;

        ALTER TABLE `_who_last_signin` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE plsport_playsport._who_last_signin ADD INDEX (`userid`);

CREATE TABLE plsport_playsport._applelist2 engine = myisam
SELECT a.userid, a.sent_text, a.nickname, a.browses, a.CREATEon, b.last_sign_in
FROM plsport_playsport._applelist1 a LEFT JOIN plsport_playsport._who_last_signin b on a.userid = b.userid;

# 登入的次數
CREATE TABLE plsport_playsport._signin_count engine = myisam
SELECT userid, count(signin_time) as sign_in_count
FROM plsport_playsport.member_signin_log_archive
GROUP BY userid
ORDER BY signin_time DESC;

        ALTER TABLE `_signin_count` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE plsport_playsport._signin_count ADD INDEX (`userid`);

CREATE TABLE plsport_playsport._applelist3 engine = myisam
SELECT a.userid, a.sent_text, a.nickname, a.browses, a.CREATEon, a.last_sign_in, b.sign_in_count
FROM plsport_playsport._applelist2 a LEFT JOIN plsport_playsport._signin_count b on a.userid = b.userid;

# 使用抵用券的次數
CREATE TABLE plsport_playsport._coupon_used_count engine = myisam
SELECT userid, count(id) as coupon_used_count
FROM plsport_playsport.coupon_used_detail
WHERE type = 1
GROUP BY userid;

        ALTER TABLE `_coupon_used_count` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE plsport_playsport._coupon_used_count ADD INDEX (`userid`);

CREATE TABLE plsport_playsport._applelist4 engine = myisam
SELECT a.userid, a.sent_text, a.nickname, a.browses, a.CREATEon, a.last_sign_in, a.sign_in_count, b.coupon_used_count
FROM plsport_playsport._applelist3 a LEFT JOIN plsport_playsport._coupon_used_count b on a.userid = b.userid;

# 花了多少噱幣
CREATE TABLE plsport_playsport._pcash_log engine = myisam
SELECT userid, sum(amount) as total_spent
FROM plsport_playsport.pcash_log
WHERE payed = 1 AND type = 1
GROUP BY userid;

# 儲值了多少噱幣
CREATE TABLE plsport_playsport._order_data engine = myisam
SELECT userid, sum(price) as redeem_total 
FROM plsport_playsport.order_data
WHERE sellconfirm = 1
GROUP BY userid;

        ALTER TABLE `_pcash_log` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE plsport_playsport._pcash_log ADD INDEX (`userid`);
        ALTER TABLE `_order_data` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE plsport_playsport._order_data ADD INDEX (`userid`);

CREATE TABLE plsport_playsport._applelist5 engine = myisam
SELECT a.userid, a.sent_text, a.nickname, a.browses, a.CREATEon, a.last_sign_in, a.sign_in_count, a.coupon_used_count, b.total_spent
FROM plsport_playsport._applelist4 a LEFT JOIN plsport_playsport._pcash_log b on a.userid = b.userid;

CREATE TABLE plsport_playsport._applelist6 engine = myisam
SELECT a.userid, a.sent_text, a.nickname, a.browses, a.CREATEon, a.last_sign_in, a.sign_in_count, a.coupon_used_count, a.total_spent, b.redeem_total
FROM plsport_playsport._applelist5 a LEFT JOIN plsport_playsport._order_data b on a.userid = b.userid;


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
CREATE TABLE plsport_playsport._who_buy_in_one_month engine = myisam
SELECT a.userid, sum(a.amount) as total_spent
FROM (
    SELECT * 
    FROM plsport_playsport.pcash_log
    WHERE payed = 1 AND type = 1
    AND date between subdate(now(),31) AND now()) as a # 區間1個月
GROUP BY a.userid;

        # 結合perdict_buyer和predict_seller
        CREATE TABLE plsport_playsport._predict_buyer engine = myisam
        SELECT buyerid, buy_date, buy_price, id_bought 
        FROM plsport_playsport.predict_buyer
        WHERE year(buy_date) = 2014;

        CREATE TABLE plsport_playsport._predict_seller engine = myisam
        SELECT id, sellerid, sale_date  
        FROM plsport_playsport.predict_seller
        WHERE year(sale_date) = 2014;

                ALTER TABLE plsport_playsport._predict_buyer  ADD INDEX (`buyerid`);
                ALTER TABLE plsport_playsport._predict_seller ADD INDEX (`id`);

        CREATE TABLE plsport_playsport._predict_buyer_AND_seller engine = myisam
        SELECT a.buyerid, a.buy_date, a.buy_price, b.sellerid, b.sale_date 
        FROM plsport_playsport._predict_buyer a LEFT JOIN plsport_playsport._predict_seller b on a.id_bought = b.id;


# 誰在近6個月內有賣牌
CREATE TABLE plsport_playsport._who_earn_in_three_month engine = myisam
SELECT b.sellerid, b.total_earn
FROM (
    SELECT a.sellerid, sum(a.buy_price) as total_earn
    FROM (
        SELECT sellerid, buy_date, buy_price, buyerid
        FROM plsport_playsport._predict_buyer_AND_seller
        WHERE buy_date between subdate(now(),186) AND now() # 區間6個月
        ORDER BY buy_date DESC) as a 
    GROUP BY a.sellerid) as b
ORDER BY b.total_earn DESC;

# perFROM outer join in mysql
# SELECT * FROM t1
# LEFT JOIN t2 ON t1.id = t2.id
# UNION
# SELECT * FROM t1
# RIGHT JOIN t2 ON t1.id = t2.id

# merge (1)誰在近1個月內有消費和(2)誰在近6個月內有賣牌
CREATE TABLE plsport_playsport._outer_join_full_list engine = myisam
SELECT * FROM plsport_playsport._who_buy_in_one_month a LEFT JOIN plsport_playsport._who_earn_in_three_month b on a.userid = b.sellerid
UNION
SELECT * FROM plsport_playsport._who_buy_in_one_month a right join plsport_playsport._who_earn_in_three_month b on a.userid = b.sellerid;

# 輸出.txt
SELECT 'userid', 'total_spent', 'sellerid', 'total_earn' UNION(
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_outer_join_full_list.txt'
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
# =================================================================================================

CREATE TABLE plsport_playsport._predict_seller_team_new engine = myisam
SELECT id, mode, allianceid, gamedate, gameid, is_sellable, sellers_count, CREATE_time, date(CREATE_time) as d,
       hour(CREATE_time) as h, sellable_time
FROM plsport_playsport.predict_seller_team_new
WHERE allianceid in (1,2)
ORDER BY CREATE_time, allianceid;




# =================================================================================================
# 任務: [201401-K-7]網站首頁改版-優化ABTESEING [進行中] (靜怡) 2014-08-06
# 
# (a)購買沒有成功例子(沒登入去按購買, 有登入但沒噱幣)
# 去撈action_log
# /click_buy_button_FROM_index.php?FROM=IDX
# /click_buy_button_FROM_index.php?FROM=IDX_C
# 
# (b)購買成功的例子
# 直接撈predict_buyer購買位置追蹤的購買次數
# 
# 點擊率的統計就是(a) + (b)
# =================================================================================================


CREATE TABLE actionlog._action_201407_click_buy_button_FROM_index engine = myisam
SELECT id, userid, uri, time 
FROM actionlog.action_201407
WHERE uri LIKE '%click_buy_button_FROM_index.php?FROM=IDX%';

CREATE TABLE actionlog._action_201408_click_buy_button_FROM_index engine = myisam
SELECT id, userid, uri, time 
FROM actionlog.action_201408
WHERE uri LIKE '%click_buy_button_FROM_index.php?FROM=IDX%';

CREATE TABLE actionlog._action_click_buy_button_FROM_index engine = myisam
SELECT * FROM actionlog._action_201407_click_buy_button_FROM_index;
INSERT IGNORE INTO actionlog._action_click_buy_button_FROM_index 
SELECT * FROM actionlog._action_201408_click_buy_button_FROM_index;

CREATE TABLE actionlog._action_click_buy_button_FROM_index_edited engine = myisam
SELECT id, userid, uri, substr(uri,locate('FROM=',uri)+5,length(uri)) as p, time
FROM actionlog._action_click_buy_button_FROM_index
WHERE time between '2014-07-19 00:00:00' AND '2014-08-01 12:00:00';

CREATE TABLE plsport_playsport._predict_buyer_with_cons_edited engine = myisam
SELECT * 
FROM plsport_playsport._predict_buyer_with_cons
WHERE buy_date between '2014-07-19 00:00:00' AND '2014-08-01 12:00:00'
AND substr(position,1,3) = 'IDX';


# 查詢計數 - 未成功的購買
SELECT p, count(userid) as c 
FROM actionlog._action_click_buy_button_FROM_index_edited
GROUP BY p;

# 查詢計數 - 有成功的購買
SELECT a.position, count(a.buyerid) as c, sum(a.buy_price) as spent
FROM (
    SELECT * 
    FROM plsport_playsport._predict_buyer_with_cons
    WHERE buy_date between '2014-07-19 00:00:00' AND '2014-08-01 12:00:00'
    AND substr(position,1,3) = 'IDX') as a
GROUP BY a.position;


CREATE TABLE actionlog._action_click_buy_button_FROM_index_edited_all engine = myisam
SELECT userid, p, time
FROM actionlog._action_click_buy_button_FROM_index_edited
UNION
SELECT buyerid as userid, position as p, buy_date as time
FROM plsport_playsport._predict_buyer_with_cons_edited;

    ALTER TABLE `_action_click_buy_button_FROM_index_edited_all` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '';

CREATE TABLE actionlog._action_click_buy_button_FROM_index_edited_all_member engine = myisam
SELECT a.userid, b.CREATEon, a.p, a.time 
FROM actionlog._action_click_buy_button_FROM_index_edited_all a LEFT JOIN plsport_playsport.member b on a.userid = b.userid
WHERE a.userid <> '';


SELECT * 
FROM actionlog._action_click_buy_button_FROM_index_edited_all_member
ORDER BY CREATEon DESC;


SELECT b.p, b.join_m, count(b.userid) as c
FROM (
    SELECT a.userid, a.join_m, a.p, count(a.userid) as c
    FROM (
        SELECT userid, substr(CREATEon,1,7) as join_m, p
        FROM actionlog._action_click_buy_button_FROM_index_edited_all_member
        ORDER BY CREATEon DESC) as a
    GROUP BY a.userid, a.join_m, a.p) as b 
GROUP BY b.p, b.join_m;


SELECT a.p, a.join_m, count(a.userid) as c
FROM (
    SELECT userid, substr(CREATEon,1,7) as join_m, p
    FROM actionlog._action_click_buy_button_FROM_index_edited_all_member
    ORDER BY CREATEon DESC) as a
GROUP BY a.p, a.join_m;


SELECT *
FROM (
    SELECT a.userid, a.join_m, a.p, count(a.userid) as c
    FROM (
        SELECT userid, substr(CREATEon,1,7) as join_m, p
        FROM actionlog._action_click_buy_button_FROM_index_edited_all_member
        ORDER BY CREATEon DESC) as a
    GROUP BY a.userid, a.join_m, a.p) as b
ORDER BY b.c DESC;


CREATE TABLE actionlog._action_201407_goforum_FROM_index engine = myisam
SELECT id, userid, uri, time 
FROM actionlog.action_201407
WHERE uri LIKE '%forumdetail.php%'
AND time between '2014-07-19 00:00:00' AND '2014-08-01 12:00:00';

CREATE TABLE actionlog._action_201408_goforum_FROM_index engine = myisam
SELECT id, userid, uri, time 
FROM actionlog.action_201408
WHERE uri LIKE '%forumdetail.php%'
AND time between '2014-07-19 00:00:00' AND '2014-08-01 12:00:00';


CREATE TABLE actionlog._action_goforum_FROM_index engine = myisam
SELECT * FROM actionlog._action_201407_goforum_FROM_index;
INSERT IGNORE INTO actionlog._action_goforum_FROM_index
SELECT * FROM actionlog._action_201408_goforum_FROM_index;

CREATE TABLE actionlog._action_goforum_FROM_index_1 engine = myisam
SELECT * 
FROM actionlog._action_goforum_FROM_index
WHERE uri LIKE '%FROM=I%';

CREATE TABLE actionlog._action_goforum_FROM_index_2 engine = myisam
SELECT userid, uri, substr(uri,locate('FROM=',uri)+5,length(uri)) as p, substr(time,1,7) as m 
FROM actionlog._action_goforum_FROM_index_1;

    ALTER TABLE `_action_goforum_FROM_index_2` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '';

CREATE TABLE actionlog._action_goforum_FROM_index_3 engine = myisam
SELECT a.userid, substr(b.CREATEon,1,7) as join_month, a.uri, a.p, a.m
FROM actionlog._action_goforum_FROM_index_2 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;


SELECT p, join_month, count(userid) as c 
FROM actionlog._action_goforum_FROM_index_3
WHERE userid <> ''
GROUP BY p, join_month;


SELECT b.pp, b.join_month, count(b.userid) as c
FROM (
    SELECT a.pp, a.join_month, a.userid, count(a.userid) as c
    FROM (
        SELECT userid, join_month, p, 
               (case when (p = 'ID') then 'IDX'
                     when (p = 'IDX_C') then 'IDX_C'
                     else 'IDX' end) as pp, m
        FROM actionlog._action_goforum_FROM_index_3
        WHERE userid <> '') as a 
    GROUP BY a.pp, a.join_month, a.userid) as b
GROUP BY b.pp, b.join_month;



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

CREATE TABLE actionlog_users_pv.action_livescore_201404 engine = myisam
SELECT userid, uri, time, (case when (platform_type = 1) then 'PC' else 'mobile' end) as platform
FROM actionlog.action_201404
WHERE userid <> '' AND uri LIKE '%livescore.php%';

CREATE TABLE actionlog_users_pv.action_livescore_201405 engine = myisam
SELECT userid, uri, time, (case when (platform_type = 1) then 'PC' else 'mobile' end) as platform
FROM actionlog.action_201405
WHERE userid <> '' AND uri LIKE '%livescore.php%';

CREATE TABLE actionlog_users_pv.action_livescore_201406 engine = myisam
SELECT userid, uri, time, (case when (platform_type = 1) then 'PC' else 'mobile' end) as platform
FROM actionlog.action_201406
WHERE userid <> '' AND uri LIKE '%livescore.php%';

CREATE TABLE actionlog_users_pv.action_livescore_201407 engine = myisam
SELECT userid, uri, time, (case when (platform_type = 1) then 'PC' else 'mobile' end) as platform
FROM actionlog.action_201407
WHERE userid <> '' AND uri LIKE '%livescore.php%';

CREATE TABLE actionlog_users_pv.action_livescore engine = myisam
SELECT * FROM actionlog_users_pv.action_livescore_201404;
INSERT IGNORE INTO actionlog_users_pv.action_livescore SELECT * FROM actionlog_users_pv.action_livescore_201405;
INSERT IGNORE INTO actionlog_users_pv.action_livescore SELECT * FROM actionlog_users_pv.action_livescore_201406;
INSERT IGNORE INTO actionlog_users_pv.action_livescore SELECT * FROM actionlog_users_pv.action_livescore_201407;

drop TABLE actionlog_users_pv.action_livescore_201404;
drop TABLE actionlog_users_pv.action_livescore_201405;
drop TABLE actionlog_users_pv.action_livescore_201406;
drop TABLE actionlog_users_pv.action_livescore_201407;

CREATE TABLE actionlog_users_pv.action_livescore_1 engine = myisam
SELECT userid, uri, (case when (locate('aid=',uri))=0 then 0 else substr(uri,locate('aid=',uri)+4,length(uri)) end) as m, time, platform 
FROM actionlog_users_pv.action_livescore;

CREATE TABLE actionlog_users_pv.action_livescore_2 engine = myisam
SELECT userid, uri, m, (case when (locate('&',m)=0) then m else substr(m,1,locate('&',m)-1) end) as aid, time, platform
FROM actionlog_users_pv.action_livescore_1;

CREATE TABLE actionlog_users_pv.action_livescore_3 engine = myisam
SELECT userid, uri, (case when (aid=0) then 1 else aid end) as aid, time, platform 
FROM actionlog_users_pv.action_livescore_2;

# --名單區--
# (1)取得問券中使用者對即時比分的評價
CREATE TABLE plsport_playsport._livescore_score engine = myisam
SELECT userid, livescore_score, livescore_improve
FROM plsport_playsport.satisfactionquestionnaire_answer
WHERE livescore_notused = 0;

# (2)產生_city_info_ok_with_chinese居住地資訊
#    --執行之前寫的SQL

# (3)nickname


# (4)最後一次登入的時間
CREATE TABLE plsport_playsport._last_signin engine = myisam # 最近一次登入
SELECT userid, max(signin_time) as last_signin
FROM plsport_playsport.member_signin_log_archive
GROUP BY userid;

        ALTER TABLE plsport_playsport._last_signin ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._livescore_score ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._city_info_ok_with_chinese ADD INDEX (`userid`);

        ALTER TABLE `_livescore_score` CHANGE `userid` `userid` VARCHAR(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE `_city_info_ok_with_chinese` CHANGE `userid` `userid` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE `_last_signin` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

# --------------------------------------------
# 從這裡開始製作名單 (第二份名單就直接改日期) 
# --------------------------------------------

CREATE TABLE actionlog_users_pv._action_livescore_3_pv_total engine = myisam # 即時比分的pv
SELECT userid, count(userid) as pv_total 
FROM actionlog_users_pv.action_livescore_3
WHERE time between '2014-06-15 00:00:00' AND '2014-07-31 23:59:59'
GROUP BY userid;

        CREATE TABLE actionlog_users_pv._action_livescore_3_pv_mlb engine = myisam # 即時比分的pv - MLB
        SELECT userid, count(userid) as pv_total 
        FROM actionlog_users_pv.action_livescore_3
        WHERE time between '2014-06-15 00:00:00' AND '2014-07-31 23:59:59' AND aid = 1
        GROUP BY userid;

        CREATE TABLE actionlog_users_pv._action_livescore_3_pv_jpb engine = myisam # 即時比分的pv - 日棒
        SELECT userid, count(userid) as pv_total 
        FROM actionlog_users_pv.action_livescore_3
        WHERE time between '2014-06-15 00:00:00' AND '2014-07-31 23:59:59' AND aid = 2
        GROUP BY userid;

        CREATE TABLE actionlog_users_pv._action_livescore_3_pv_cpb engine = myisam # 即時比分的pv - 中職
        SELECT userid, count(userid) as pv_total 
        FROM actionlog_users_pv.action_livescore_3
        WHERE time between '2014-06-15 00:00:00' AND '2014-07-31 23:59:59' AND aid = 6
        GROUP BY userid;

        CREATE TABLE actionlog_users_pv._action_livescore_3_pv_device engine = myisam # 即時比分的pv - 裝罝
        SELECT b.userid, sum(b.pv_PC) as pv_PC, sum(b.pv_mobile) as pv_mobile
        FROM (
            SELECT a.userid, (case when (a.platform='PC') then c else 0 end) as pv_PC, (case when (a.platform='mobile') then c else 0 end) as pv_mobile
            FROM (
                SELECT userid, platform, count(userid) as c
                FROM actionlog_users_pv.action_livescore_3
                WHERE time between '2014-06-15 00:00:00' AND '2014-07-31 23:59:59'
                GROUP BY userid, platform) as a) as b
        GROUP BY b.userid;

        CREATE TABLE actionlog_users_pv._action_livescore_3_pv_device_1 engine = myisam # 即時比分的pv - 裝罝比例(使用這個)
        SELECT userid, pv_PC, pv_mobile, round(pv_PC/(pv_PC+pv_mobile),2) as PC_precent, round(pv_mobile/(pv_PC+pv_mobile),2) as Mobile_precent
        FROM actionlog_users_pv._action_livescore_3_pv_device;

                ALTER TABLE actionlog_users_pv._action_livescore_3_pv_total ADD INDEX (`userid`);
                ALTER TABLE actionlog_users_pv._action_livescore_3_pv_mlb ADD INDEX (`userid`);
                ALTER TABLE actionlog_users_pv._action_livescore_3_pv_jpb ADD INDEX (`userid`);
                ALTER TABLE actionlog_users_pv._action_livescore_3_pv_cpb ADD INDEX (`userid`);
                ALTER TABLE actionlog_users_pv._action_livescore_3_pv_device_1 ADD INDEX (`userid`);


CREATE TABLE actionlog_users_pv.action_livescore_4 engine = myisam
SELECT c.userid, c.nickname, date(c.CREATEon) as join_date, date(d.last_signin) as last_signin, c.pv_total
FROM (
    SELECT a.userid, b.nickname, b.CREATEon, a.pv_total  
    FROM actionlog_users_pv._action_livescore_3_pv_total a LEFT JOIN plsport_playsport.member b on a.userid = b.userid) as c
    LEFT JOIN plsport_playsport._last_signin d on c.userid = d.userid;

CREATE TABLE actionlog_users_pv.action_livescore_5 engine = myisam
SELECT e.userid, e.nickname, e.join_date, e.last_signin, e.pv_total, e.pv_mlb, e.pv_jpb, f.pv_total as pv_cpb
FROM (
    SELECT c.userid, c.nickname, c.join_date, c.last_signin, c.pv_total, c.pv_mlb, d.pv_total as pv_jpb
    FROM (
        SELECT a.userid, a.nickname, a.join_date, a.last_signin, a.pv_total, b.pv_total as pv_mlb
        FROM actionlog_users_pv.action_livescore_4 a LEFT JOIN actionlog_users_pv._action_livescore_3_pv_mlb b on a.userid = b.userid) as c
        LEFT JOIN actionlog_users_pv._action_livescore_3_pv_jpb d on c.userid = d.userid) as e
    LEFT JOIN actionlog_users_pv._action_livescore_3_pv_cpb as f on e.userid = f.userid;


# 名單1
CREATE TABLE actionlog_users_pv.action_livescore_6_list1 engine = myisam
SELECT e.userid, e.nickname, e.join_date, e.last_signin, e.pv_total, e.pv_mlb, e.pv_jpb, e.pv_cpb, 
       e.pv_PC, e.pv_mobile, e.PC_precent, e.Mobile_precent, e.city, f.livescore_score, f.livescore_improve
FROM (
    SELECT c.userid, c.nickname, c.join_date, c.last_signin, c.pv_total, c.pv_mlb, c.pv_jpb, c.pv_cpb, 
           c.pv_PC, c.pv_mobile, c.PC_precent, c.Mobile_precent, d.city1 as city
    FROM (
        SELECT a.userid, a.nickname, a.join_date, a.last_signin, a.pv_total, a.pv_mlb, a.pv_jpb, a.pv_cpb, b.pv_PC, b.pv_mobile, b.PC_precent, b.Mobile_precent
        FROM actionlog_users_pv.action_livescore_5 a LEFT JOIN actionlog_users_pv._action_livescore_3_pv_device_1 b on a.userid = b.userid) as c 
    LEFT JOIN plsport_playsport._city_info_ok_with_chinese as d on c.userid = d.userid) as e
LEFT JOIN plsport_playsport._livescore_score as f on e.userid = f.userid;

# 名單2
CREATE TABLE actionlog_users_pv.action_livescore_6_list2 engine = myisam
SELECT e.userid, e.nickname, e.join_date, e.last_signin, e.pv_total, e.pv_mlb, e.pv_jpb, e.pv_cpb, 
       e.pv_PC, e.pv_mobile, e.PC_precent, e.Mobile_precent, e.city, f.livescore_score, f.livescore_improve
FROM (
    SELECT c.userid, c.nickname, c.join_date, c.last_signin, c.pv_total, c.pv_mlb, c.pv_jpb, c.pv_cpb, 
           c.pv_PC, c.pv_mobile, c.PC_precent, c.Mobile_precent, d.city1 as city
    FROM (
        SELECT a.userid, a.nickname, a.join_date, a.last_signin, a.pv_total, a.pv_mlb, a.pv_jpb, a.pv_cpb, b.pv_PC, b.pv_mobile, b.PC_precent, b.Mobile_precent
        FROM actionlog_users_pv.action_livescore_5 a LEFT JOIN actionlog_users_pv._action_livescore_3_pv_device_1 b on a.userid = b.userid) as c 
    LEFT JOIN plsport_playsport._city_info_ok_with_chinese as d on c.userid = d.userid) as e
LEFT JOIN plsport_playsport._livescore_score as f on e.userid = f.userid;


CREATE TABLE actionlog_users_pv.action_livescore_6_list1_edited engine = myisam
SELECT b.id, a.userid, a.nickname, a.join_date, a.last_signin, a.pv_total, a.pv_mlb, a.pv_jpb, a.pv_cpb, a.pv_PC, a.pv_mobile, a.PC_precent, a.Mobile_precent,
       a.city, a.livescore_score, a.livescore_improve 
FROM actionlog_users_pv.action_livescore_6_list1 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;


CREATE TABLE actionlog_users_pv.action_livescore_6_list2_edited engine = myisam
SELECT b.id, a.userid, a.nickname, a.join_date, a.last_signin, a.pv_total, a.pv_mlb, a.pv_jpb, a.pv_cpb, a.pv_PC, a.pv_mobile, a.PC_precent, a.Mobile_precent,
       a.city, a.livescore_score, a.livescore_improve 
FROM actionlog_users_pv.action_livescore_6_list2 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;



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


CREATE TABLE actionlog.action_usersearch_201405 engine = myisam
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201405 WHERE userid <> '' AND uri LIKE '%usersearch.php%';
CREATE TABLE actionlog.action_usersearch_201406 engine = myisam
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201406 WHERE userid <> '' AND uri LIKE '%usersearch.php%';
CREATE TABLE actionlog.action_usersearch_201407 engine = myisam
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201407 WHERE userid <> '' AND uri LIKE '%usersearch.php%';
CREATE TABLE actionlog.action_usersearch_201408 engine = myisam
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201408 WHERE userid <> '' AND uri LIKE '%usersearch.php%';

CREATE TABLE actionlog.action_usersearch engine = myisam
SELECT * FROM actionlog.action_usersearch_201405;
INSERT IGNORE INTO actionlog.action_usersearch SELECT * FROM actionlog.action_usersearch_201406;
INSERT IGNORE INTO actionlog.action_usersearch SELECT * FROM actionlog.action_usersearch_201407;
INSERT IGNORE INTO actionlog.action_usersearch SELECT * FROM actionlog.action_usersearch_201408;

CREATE TABLE actionlog._action_usersearch engine = myisam
SELECT userid, uri, time, (case when (platform_type = 1) then 'pc' else 'mobile' end) as platform
FROM actionlog.action_usersearch;



# 使用玩家搜尋pv
CREATE TABLE plsport_playsport._user_use_usersearch_count engine = myisam
SELECT userid, count(uri) as us_count 
FROM actionlog.action_usersearch
WHERE time between subdate(now(),93) AND now()
GROUP BY userid;

# 使用玩家搜尋pv-裝置devices
CREATE TABLE plsport_playsport._user_use_usersearch_platform engine = myisam
SELECT c.userid, sum(c.pc_pv) as pc_pv, sum(c.mobile_pv) as mobile_pv
FROM (
    SELECT b.userid, (case when (b.pc_pv is not null) then b.pc_pv else 0 end) as pc_pv, (case when (b.mobile_pv is not null) then b.mobile_pv else 0 end) as mobile_pv
    FROM (
        SELECT a.userid, (case when (a.platform_type=1) then c end) as pc_pv, (case when (a.platform_type>1) then c end) as mobile_pv
        FROM (
            SELECT userid, platform_type, count(uri) as c 
            FROM actionlog.action_usersearch
            WHERE time between subdate(now(),93) AND now()
            GROUP BY userid, platform_type) as a) as b) as c
GROUP BY c.userid;

# 最近一次的登入時間
CREATE TABLE plsport_playsport._last_login_time engine = myisam
SELECT userid, max(signin_time) as last_login
FROM plsport_playsport.member_signin_log_archive
GROUP BY userid;

ALTER TABLE plsport_playsport._last_login_time ADD INDEX (`userid`);  

# 近3個月有消費名單
CREATE TABLE plsport_playsport._user_spent_in_three_month engine = myisam
SELECT userid, sum(amount) as spent_pcash 
FROM plsport_playsport.pcash_log
WHERE payed = 1 AND type = 1
AND date between subdate(now(),93) AND now()
GROUP BY userid;

# 最後一次購買預測的時間
CREATE TABLE plsport_playsport._user_spent_last_time engine = myisam
SELECT userid, amount, max(date) as last_pay_date
FROM plsport_playsport.pcash_log
WHERE payed = 1 AND type = 1
GROUP BY userid;

ALTER TABLE plsport_playsport._user_spent_last_time ADD INDEX (`userid`);  


        # 玩家搜尋消費金額<-使用之前的code line:3067
        drop TABLE if exists plsport_playsport._predict_buyer;
        drop TABLE if exists plsport_playsport._predict_buyer_with_cons;

        #此段SQL是計算各購牌位置記錄的金額
        #先predict_buyer + predict_buyer_cons_split
        CREATE TABLE plsport_playsport._predict_buyer engine = myisam
        SELECT a.id, a.buyerid, a.id_bought, a.buy_date , a.buy_price, b.position, b.cons, b.allianceid
        FROM plsport_playsport.predict_buyer a LEFT JOIN plsport_playsport.predict_buyer_cons_split b on a.id = b.id_predict_buyer
        WHERE a.buy_price <> 0
        AND a.buy_date between subdate(now(),93) AND now(); #2014/03/04是開始有購牌追蹤代碼的日子

        ALTER TABLE plsport_playsport._predict_buyer ADD INDEX (`id_bought`);  

        #再join predict_seller
        CREATE TABLE plsport_playsport._predict_buyer_with_cons engine = myisam
        SELECT c.id, c.buyerid, c.id_bought, d.sellerid ,c.buy_date , c.buy_price, c.position, c.cons, c.allianceid
        FROM plsport_playsport._predict_buyer c LEFT JOIN plsport_playsport.predict_seller d on c.id_bought = d.id
        ORDER BY buy_date DESC;

        #計算各購牌位置記錄的金額
        CREATE TABLE plsport_playsport._buy_position engine = myisam
        SELECT d.buyerid, d.BRC, d.BZ, d.FRND, d.FR, d.WPB, d.MPB, d.IDX, d.HT, d.US, d.NONE, 
               (d.BRC+d.BZ+d.FRND+d.FR+d.WPB+d.MPB+d.IDX+d.HT+d.US+d.NONE) as total #把所有的金額加起來
        FROM (
                SELECT c.buyerid, sum(c.BRC) as BRC, sum(c.BZ) as BZ, sum(c.FRND) as FRND, sum(c.FR) as FR, 
                                  sum(c.WPB) as WPB, sum(c.MPB) as MPB, sum(c.IDX) as IDX, sum(c.HT) as HT,
                                  sum(c.US) as US, sum(c.NONE) as NONE
                FROM (
                        SELECT b.buyerid, 
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
                        FROM (
                                SELECT a.buyerid, a.p, sum(a.buy_price) as spent
                                FROM (
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
                                GROUP BY a.buyerid, a.p) as b) as c
                GROUP BY c.buyerid) as d;
        ALTER TABLE  `_buy_position` CHANGE  `buyerid`  `buyerid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT  '購買者userid';
        ALTER TABLE plsport_playsport._buy_position ADD INDEX (`buyerid`); 



CREATE TABLE plsport_playsport._list_1 engine = myisam
SELECT b.id, a.userid, b.nickname, a.spent_pcash 
FROM plsport_playsport._user_spent_in_three_month a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_2 engine = myisam
SELECT a.id, a.userid, a.nickname, a.spent_pcash, b.BRC, b.BZ, b.FRND, b.FR, b.WPB, b.MPB, b.IDX, b.HT, b.US, b.NONE, b.total 
FROM plsport_playsport._list_1 a LEFT JOIN plsport_playsport._buy_position b on a.userid = b.buyerid;

CREATE TABLE plsport_playsport._list_3 engine = myisam
SELECT a.id, a.userid, a.nickname, a.spent_pcash, a.BRC, a.BZ, a.FRND, a.FR, a.WPB, a.MPB, a.IDX, a.HT, a.US, a.NONE, a.total, b.us_count
FROM plsport_playsport._list_2 a LEFT JOIN plsport_playsport._user_use_usersearch_count b on a.userid = b.userid;

        ALTER TABLE plsport_playsport._user_use_usersearch_platform ADD INDEX (`userid`); 

CREATE TABLE plsport_playsport._list_4 engine = myisam
SELECT a.id, a.userid, a.nickname, a.spent_pcash, a.BRC, a.BZ, a.FRND, a.FR, a.WPB, a.MPB, a.IDX, a.HT, a.US, a.NONE, a.total, a.us_count, b.pc_pv, b.mobile_pv
FROM plsport_playsport._list_3 a LEFT JOIN plsport_playsport._user_use_usersearch_platform b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_5 engine = myisam
SELECT a.id, a.userid, a.nickname, a.spent_pcash, a.BRC, a.BZ, a.FRND, a.FR, a.WPB, a.MPB, a.IDX, a.HT, a.US, a.NONE, a.total, a.us_count, a.pc_pv, a.mobile_pv,
       b.last_pay_date
FROM plsport_playsport._list_4 a LEFT JOIN plsport_playsport._user_spent_last_time b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_6 engine = myisam
SELECT a.id, a.userid, a.nickname, a.spent_pcash, a.BRC, a.BZ, a.FRND, a.FR, a.WPB, a.MPB, a.IDX, a.HT, a.US, a.NONE, a.total, a.us_count, a.pc_pv, a.mobile_pv,
       date(a.last_pay_date) as last_pay_date, date(b.last_login) as last_login_date
FROM plsport_playsport._list_5 a LEFT JOIN plsport_playsport._last_login_time b on a.userid = b.userid
WHERE a.us_count is not null
ORDER BY a.us_count DESC;


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

CREATE TABLE plsport_playsport._user_total_spent engine = myisam
SELECT userid, sum(amount) as total_spent 
FROM plsport_playsport.pcash_log
WHERE payed = 1 AND type = 1 
GROUP BY userid;

        ALTER TABLE plsport_playsport.pcash ADD INDEX (`id_this_type`); 
        ALTER TABLE plsport_playsport.predict_seller ADD INDEX (`id`); 

CREATE TABLE plsport_playsport._user_total_earn engine = myisam
SELECT c.sellerid as userid, sum(c.sale_price) as total_earn
FROM (
    SELECT a.userid, a.amount, b.sellerid, b.sale_price 
    FROM plsport_playsport.pcash_log a LEFT JOIN plsport_playsport.predict_seller b on a.id_this_type = b.id
    WHERE a.payed = 1 AND a.type = 1) as c
WHERE c.sellerid is not null
GROUP BY c.sellerid;

        ALTER TABLE plsport_playsport._user_total_earn ADD INDEX (`userid`); 
        ALTER TABLE plsport_playsport._user_total_spent ADD INDEX (`userid`); 

CREATE TABLE plsport_playsport._user_spent_AND_earn engine = myisam
SELECT c.id, c.userid, c.nickname, c.CREATEon, c.total_spent, d.total_earn
FROM (
    SELECT a.id, a.userid, a.nickname, a.CREATEon, b.total_spent
    FROM plsport_playsport.member a LEFT JOIN plsport_playsport._user_total_spent b on a.userid = b.userid) as c
    LEFT JOIN plsport_playsport._user_total_earn as d on c.userid = d.userid
WHERE c.total_spent is not null or d.total_earn is not null;

        ALTER TABLE plsport_playsport._user_spent_AND_earn ADD INDEX (`userid`); 

# (1)殺手
CREATE TABLE plsport_playsport._qu_seller_answer engine = myisam
SELECT a.userid, b.nickname, date(b.CREATEon) as CREATEon, date(a.write_time) as write_time, b.total_spent, b.total_earn, a.spend_minute, 
       a.question01, a.question02, a.question03, a.question04, a.question05, a.question06, a.question07
FROM plsport_playsport.questionnaire_badwinningsellersuggestions_answer a LEFT JOIN plsport_playsport._user_spent_AND_earn b on a.userid = b.userid
WHERE spend_minute > 0.5
ORDER BY question07 DESC;

# (2)消費者
CREATE TABLE plsport_playsport._qu_buyer_answer engine = myisam
SELECT a.userid, b.nickname, date(b.CREATEon) as CREATEon, date(a.write_time) as write_time, b.total_spent, b.total_earn, a.spend_minute, 
       a.question01, a.question02, a.question03, a.question04, a.question05, a.question06, a.question07
FROM plsport_playsport.questionnaire_badwinningbuyersuggestions_answer a LEFT JOIN plsport_playsport._user_spent_AND_earn b on a.userid = b.userid
WHERE spend_minute > 0.5
ORDER BY question07 DESC;



# =================================================================================================
# 任務: [201407-F-1] 即時比分APP使用者訪談 - 訪談名單 [新建] 2014-08-25 (阿達)
# 說明
# 請提供訪談名單，供文婷約訪
# 時間：8/27 (三) 
# 訪談名單
# 1. 統計區間
# 2014/5/21起
# 2. 篩選條件
# 有點選過 iOS或ANDroid即時比分APP版標廣告的使用者
# 3. 資料欄位
#        帳號、暱稱、手機系統( ANDroid or iOS)、最近登入時間、版標點選天數、版標點選次數、即時比分問卷評價、
#        即時比分網頁版pv、手機/電腦使用比率、居住地
# =================================================================================================

CREATE TABLE actionlog._action_201405 engine = myisam 
SELECT userid, uri, time, platform_type FROM actionlog.action_201405 WHERE userid <> '' AND date(time) between '2014-05-21' AND '2014-05-30';
CREATE TABLE actionlog._action_201406 engine = myisam 
SELECT userid, uri, time, platform_type FROM actionlog.action_201406 WHERE userid <> '';
CREATE TABLE actionlog._action_201407 engine = myisam 
SELECT userid, uri, time, platform_type FROM actionlog.action_201407 WHERE userid <> '';
CREATE TABLE actionlog._action_201408 engine = myisam 
SELECT userid, uri, time, platform_type FROM actionlog.action_201408 WHERE userid <> '';
CREATE TABLE actionlog._action_201409 engine = myisam 
SELECT userid, uri, time, platform_type FROM actionlog.action_201409_28 WHERE userid <> '';

# (1)先把網頁版即時比分的pv捉出: _action_livescore
CREATE TABLE actionlog._action_livescore engine = myisam SELECT * FROM actionlog._action_201405 WHERE uri LIKE '%livescore.php%';
INSERT IGNORE INTO actionlog._action_livescore SELECT * FROM actionlog._action_201406 WHERE uri LIKE '%livescore.php%';
INSERT IGNORE INTO actionlog._action_livescore SELECT * FROM actionlog._action_201407 WHERE uri LIKE '%livescore.php%';
INSERT IGNORE INTO actionlog._action_livescore SELECT * FROM actionlog._action_201408 WHERE uri LIKE '%livescore.php%';
INSERT IGNORE INTO actionlog._action_livescore SELECT * FROM actionlog._action_201409 WHERE uri LIKE '%livescore.php%';

# 1
CREATE TABLE actionlog._action_livescore_0 engine = myisam
SELECT * FROM actionlog._action_livescore
WHERE date(time) between '2014-06-28' AND '2014-09-28'; # 近3個月

# 2
CREATE TABLE actionlog._action_livescore_1 engine = myisam
SELECT a.userid, a.devices, count(a.userid) as c
FROM (
    SELECT userid, (case when (platform_type<2) then 'desktop_pv' else 'mobile_pv' end) as devices
    FROM actionlog._action_livescore_0) as a
GROUP BY a.userid, a.devices;

# 3
CREATE TABLE actionlog._action_livescore_2 engine = myisam
SELECT a.userid, sum(a.desktop_pv) as desktop_pv, sum(a.mobile_pv) as mobile_pv
FROM (
    SELECT userid, (case when (devices='desktop_pv') then c else 0 end) as desktop_pv, 
                   (case when (devices='mobile_pv') then c else 0 end) as mobile_pv
    FROM actionlog._action_livescore_1) as a
GROUP BY a.userid;

# 4
CREATE TABLE actionlog._action_livescore_3 engine = myisam
SELECT userid, desktop_pv, mobile_pv, round(desktop_pv/(desktop_pv+mobile_pv),2) as desktop_p, 
                                      round(mobile_pv/(desktop_pv+mobile_pv),2) as mobile_p
FROM actionlog._action_livescore_2;


# (2)再處理購牌位置rp=
CREATE TABLE actionlog._action_rp engine = myisam SELECT * FROM actionlog._action_201405 WHERE uri LIKE '%rp=%';
INSERT IGNORE INTO actionlog._action_rp SELECT * FROM actionlog._action_201406 WHERE uri LIKE '%rp=%';
INSERT IGNORE INTO actionlog._action_rp SELECT * FROM actionlog._action_201407 WHERE uri LIKE '%rp=%';
INSERT IGNORE INTO actionlog._action_rp SELECT * FROM actionlog._action_201408 WHERE uri LIKE '%rp=%';
INSERT IGNORE INTO actionlog._action_rp SELECT * FROM actionlog._action_201409 WHERE uri LIKE '%rp=%';

CREATE TABLE actionlog._action_rp_0 engine = myisam
SELECT * FROM actionlog._action_rp
WHERE date(time) between '2014-06-28' AND '2014-09-28';

CREATE TABLE actionlog._action_rp_1 engine = myisam
SELECT userid, uri, time, platform_type, substr(uri, locate('rp=',uri)+3, length(uri)) as rp
FROM actionlog._action_rp_0;

CREATE TABLE actionlog._action_rp_2 engine = myisam
SELECT userid, uri, time, platform_type, rp
FROM actionlog._action_rp_1
WHERE substr(rp,1,3) in ('MSA','MSI'); # 只要即時比分就好了

CREATE TABLE actionlog._action_rp_3 engine = myisam
SELECT d.userid, d.title_hit_ANDroid, d.title_hit_ios, (d.title_hit_ANDroid+d.title_hit_ios) as title_hit_total
FROM (
    SELECT c.userid, sum(c.ANDroid) as title_hit_ANDroid, sum(c.ios) as title_hit_ios
    FROM (
        SELECT b.userid, (case when (b.device='A') then c else 0 end) as ANDroid, (case when (b.device='I') then c else 0 end) as ios
        FROM (
            SELECT a.userid, a.device, count(a.userid) as c
            FROM (
                SELECT userid, platform_type, substr(rp,1,3) as rp, substr(rp,3,1) as device
                FROM actionlog._action_rp_2) as a
            GROUP BY a.userid, a.device) as b) as c
    GROUP BY c.userid) as d;

CREATE TABLE actionlog._action_rp_3_hit_days engine = myisam
SELECT b.userid, count(b.d) as hit_days
FROM (
    SELECT a.userid, a.d, count(a.userid) as c
    FROM (
        SELECT userid, date(time) as d 
        FROM actionlog._action_rp_2) as a
    GROUP BY a.userid, a.d) as b
GROUP BY b.userid;


# (3)取得問券中使用者對即時比分的評價
CREATE TABLE plsport_playsport._livescore_score engine = myisam
SELECT userid, livescore_score, livescore_improve
FROM plsport_playsport.satisfactionquestionnaire_answer
WHERE livescore_notused = 0;

# (4)產生_city_info_ok_with_chinese居住地資訊, 用之前的SQL

# (5)最後一次登入的時間
CREATE TABLE plsport_playsport._last_signin engine = myisam # 最近一次登入
SELECT userid, max(signin_time) as last_signin
FROM plsport_playsport.member_signin_log_archive
GROUP BY userid;

        ALTER TABLE plsport_playsport._last_signin ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._livescore_score ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._city_info_ok_with_chinese ADD INDEX (`userid`);
        ALTER TABLE actionlog._action_rp_3_hit_days ADD INDEX (`userid`);
        ALTER TABLE actionlog._action_rp_3 ADD INDEX (`userid`);
        ALTER TABLE actionlog._action_livescore_3 ADD INDEX (`userid`);

CREATE TABLE plsport_playsport._list1 engine = myisam
SELECT c.id, c.userid, c.nickname, c.title_hit_ANDroid, c.title_hit_ios, c.title_hit_total, d.livescore_score, d.livescore_improve
FROM (
    SELECT b.id, b.userid, b.nickname, a.title_hit_ANDroid, a.title_hit_ios, a.title_hit_total
    FROM actionlog._action_rp_3 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid) as c 
    LEFT JOIN plsport_playsport._livescore_score as d on c.userid = d.userid;

CREATE TABLE plsport_playsport._list2 engine = myisam
SELECT c.id, c.userid, c.nickname, c.last_signin, c.title_hit_ANDroid, c.title_hit_ios, c.title_hit_total, d.hit_days ,c.livescore_score, c.livescore_improve
FROM (
    SELECT a.id, a.userid, a.nickname, date(b.last_signin) as last_signin, 
           a.title_hit_ANDroid, a.title_hit_ios, a.title_hit_total, a.livescore_score, a.livescore_improve
    FROM plsport_playsport._list1 a LEFT JOIN plsport_playsport._last_signin b on a.userid = b.userid) as c
    LEFT JOIN actionlog._action_rp_3_hit_days as d on c.userid = d.userid;

# 完成
CREATE TABLE plsport_playsport._list3 engine = myisam
SELECT c.id, c.userid, c.nickname, c.last_signin, c.title_hit_ANDroid, c.title_hit_ios, c.title_hit_total, c.hit_days, 
       c.desktop_pv, c.mobile_pv, c.desktop_p, c.mobile_p, d.city1, c.livescore_score, c.livescore_improve
FROM (
    SELECT a.id, a.userid, a.nickname, a.last_signin, a.title_hit_ANDroid, a.title_hit_ios, a.title_hit_total, a.hit_days, 
           b.desktop_pv, b.mobile_pv, b.desktop_p, b.mobile_p, a.livescore_score, a.livescore_improve
    FROM plsport_playsport._list2 a LEFT JOIN actionlog._action_livescore_3 b on a.userid = b.userid) as c
    LEFT JOIN plsport_playsport._city_info_ok_with_chinese as d on c.userid = d.userid;




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


CREATE TABLE actionlog._action_201408_buy_predict engine = myisam
SELECT * FROM actionlog._action_201408
WHERE uri LIKE '%buy_predict%'
AND userid <> ''
AND time between '2014-08-06 14:00:00' AND '2014-08-27 23:59:59';


CREATE TABLE actionlog._action_201408_buy_predict_1 engine = myisam
SELECT userid, uri, time, (case when (locate("sort=", uri)>0) then substr(uri, locate("sort=", uri), length(uri)) else "" end) as sort, 
                          (case when (locate("killertype=", uri)>0) then substr(uri, locate("killertype=", uri), length(uri)) else "" end) as killertype
FROM actionlog._action_201408_buy_predict;

CREATE TABLE actionlog._action_201408_buy_predict_2 engine = myisam
SELECT userid, uri, time, sort, (case when (locate("&",killertype)>0) then substr(killertype, 1,locate("&",killertype)-1) else "" end) as killertype
FROM actionlog._action_201408_buy_predict_1;


CREATE TABLE actionlog._action_201408_buy_predict_click_sort engine = myisam
SELECT * FROM actionlog._action_201408_buy_predict_2
WHERE sort <> "";


# 單純看各排序sort的點擊次數
SELECT sort, killertype, count(userid) as c 
FROM actionlog._action_201408_buy_predict_click_sort
GROUP BY sort, killertype;

# 接受測試的人有多少人? 1566人
SELECT count(a.userid)
FROM (
    SELECT userid, count(userid) as c
    FROM actionlog._action_201408_buy_predict_2
    WHERE uri LIKE '%buy_predict_b.php%'
    GROUP BY userid) as a;

SELECT count(a.userid)
FROM (
    SELECT userid, count(userid) as c 
    FROM actionlog._action_201408_buy_predict_click_sort
    WHERE sort = 'sort=6'
    AND killertype = 'killertype=singlekiller'
    GROUP BY userid) as a;

# 有多少人點過排序? 573人
SELECT count(a.userid)
FROM (
    SELECT userid, count(userid) as c 
    FROM actionlog._action_201408_buy_predict_click_sort
    WHERE sort is not null
    GROUP BY userid) as a;


CREATE TABLE plsport_playsport._predict_buyer_with_cons_1 engine = myisam
SELECT buyerid, sellerid, buy_date, buy_price, position 
FROM plsport_playsport._predict_buyer_with_cons
WHERE buy_date between '2014-08-06 14:00:00' AND '2014-08-27 23:59:59';


CREATE TABLE plsport_playsport._predict_buyer_with_cons_2 engine = myisam
SELECT c.g, (case when (c.g in (8,9,10,11,12,13)) then 'A' else 'B' end) as abtest ,c.userid, c.sellerid, c.buy_date, c.buy_price, c.position
FROM (
    SELECT (b.id%20)+1 as g, b.userid, a.sellerid, a.buy_date, a.buy_price, a.position 
    FROM plsport_playsport._predict_buyer_with_cons_1 a LEFT JOIN plsport_playsport.member b on a.buyerid = b.userid) as c;

# 全站消費者的abtesting
CREATE TABLE plsport_playsport._list_all engine = myisam
SELECT abtest, userid, sum(buy_price) as spent 
FROM plsport_playsport._predict_buyer_with_cons_2
GROUP BY abtest, userid;

# 只在購牌專區消費者的abtesting
CREATE TABLE plsport_playsport._list_BZ_area engine = myisam
SELECT abtest, userid, sum(buy_price) as spent 
FROM plsport_playsport._predict_buyer_with_cons_2
WHERE substr(position,1,3) = 'BZ_'
GROUP BY abtest, userid;

# 在購牌專區消費者的全站消費金額abtesting (2014-09-05會議後補充)
CREATE TABLE plsport_playsport._list_BZ_area_with_all engine = myisam
SELECT a.abtest, a.userid, a.spent as spent_bz, b.spent as spent_all
FROM plsport_playsport._list_bz_area a LEFT JOIN plsport_playsport._list_all b on a.userid = b.userid;


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

CREATE TABLE plsport_playsport._forum_gametype3 engine = myisam
SELECT subjectid, forumtype, allianceid, gametype, postuser, date(posttime) as posttime
FROM plsport_playsport.forum
WHERE date(posttime) between '2014-07-31' AND '2014-08-27'
AND gametype = 3;

CREATE TABLE plsport_playsport._forum_gametype_all engine = myisam
SELECT subjectid, forumtype, allianceid, gametype, postuser, date(posttime) as posttime
FROM plsport_playsport.forum
WHERE date(posttime) between '2014-07-31' AND '2014-08-27';

SELECT posttime, allianceid, count(subjectid) as post_count 
FROM plsport_playsport._forum_gametype3
GROUP BY posttime, allianceid;

SELECT posttime, allianceid, count(subjectid) as post_count 
FROM plsport_playsport._forum_gametype_all
GROUP BY posttime, allianceid;


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

CREATE TABLE plsport_playsport._medal_fire_baseball_twn engine = myisam
SELECT * FROM plsport_playsport.medal_fire
WHERE vol >119 
AND allianceid in (6,2,9)
AND winpercentage > 69
AND mode = 1
ORDER BY vol DESC;

CREATE TABLE plsport_playsport._medal_fire_baseball_int engine = myisam
SELECT * FROM plsport_playsport.medal_fire
WHERE vol >119 
AND allianceid in (6,2,9)
AND winpercentage > 69
AND mode = 2
ORDER BY vol DESC;

# 抽出中籃
CREATE TABLE plsport_playsport._medal_fire_basketball_int_94 engine = myisam
SELECT * FROM plsport_playsport.medal_fire
WHERE vol in (113,112,111,110,109,108)
AND allianceid in (94)
AND winpercentage > 69
AND mode = 2
ORDER BY vol DESC;

# 抽出韓籃
CREATE TABLE plsport_playsport._medal_fire_basketball_int_92 engine = myisam
SELECT * FROM plsport_playsport.medal_fire
WHERE vol in (114,113,112,111,110,109)
AND allianceid in (92)
AND winpercentage > 69
AND mode = 2
ORDER BY vol DESC;

# 抽出日籃
CREATE TABLE plsport_playsport._medal_fire_basketball_int_97 engine = myisam
SELECT * FROM plsport_playsport.medal_fire
WHERE vol in (116,115,114,113,112,111)
AND allianceid in (97)
AND winpercentage > 69
AND mode = 2
ORDER BY vol DESC;

# merge3個籃球聯盟
CREATE TABLE plsport_playsport._medal_fire_basketball_int engine = myisam SELECT * FROM plsport_playsport._medal_fire_basketball_int_94;
INSERT IGNORE INTO plsport_playsport._medal_fire_basketball_int SELECT * FROM plsport_playsport._medal_fire_basketball_int_92;
INSERT IGNORE INTO plsport_playsport._medal_fire_basketball_int SELECT * FROM plsport_playsport._medal_fire_basketball_int_97;

# 候選名單(亞籃殺手)
CREATE TABLE plsport_playsport._medal_fire_basketball_int_ok engine = myisam
SELECT * 
FROM (
    SELECT userid, nickname, count(userid) as killer_count, round(avg(winpercentage),0) as avg_win, round(avg(winearn),1) as avg_earn
    FROM plsport_playsport._medal_fire_basketball_int
    GROUP BY userid, nickname) as a
ORDER BY a.killer_count DESC, a.avg_win DESC, a.avg_earn DESC;

# 候選名單(亞棒殺手-國際)
CREATE TABLE plsport_playsport._medal_fire_baseball_int_ok engine = myisam
SELECT * 
FROM (
    SELECT userid, nickname, count(userid) as killer_count, round(avg(winpercentage),0) as avg_win, round(avg(winearn),1) as avg_earn
    FROM plsport_playsport._medal_fire_baseball_int
    GROUP BY userid, nickname) as a
ORDER BY a.killer_count DESC, a.avg_win DESC, a.avg_earn DESC;

# 候選名單(亞棒殺手-運彩)
CREATE TABLE plsport_playsport._medal_fire_baseball_twn_ok engine = myisam
SELECT * 
FROM (
    SELECT userid, nickname, count(userid) as killer_count, round(avg(winpercentage),0) as avg_win, round(avg(winearn),1) as avg_earn
    FROM plsport_playsport._medal_fire_baseball_twn
    GROUP BY userid, nickname) as a
ORDER BY a.killer_count DESC, a.avg_win DESC, a.avg_earn DESC;


# 禁售名單
# 本尊
CREATE TABLE plsport_playsport._block_list1 engine = myisam
SELECT master_userid as userid 
FROM plsport_playsport.sell_deny
WHERE date(time) between '2014-09-07' AND '2014-09-21';
# 分身
INSERT IGNORE INTO plsport_playsport._block_list1 
SELECT slave_userid as userid FROM plsport_playsport.sell_deny;
# 本尊+分身 then remove duplicate userid
CREATE TABLE plsport_playsport._block_list engine = myisam
SELECT userid
FROM plsport_playsport._block_list1
GROUP BY userid;

drop TABLE plsport_playsport._block_list1;

# 候選名單(亞棒殺手-國際)
SELECT * 
FROM plsport_playsport._medal_fire_baseball_int_ok a LEFT JOIN plsport_playsport._block_list b on a.userid = b.userid
WHERE b.userid is null;

# 候選名單(亞棒殺手-運彩)
SELECT * 
FROM plsport_playsport._medal_fire_baseball_twn_ok a LEFT JOIN plsport_playsport._block_list b on a.userid = b.userid
WHERE b.userid is null;

# 候選名單(亞籃殺手)
SELECT * 
FROM plsport_playsport._medal_fire_basketball_int_ok a LEFT JOIN plsport_playsport._block_list b on a.userid = b.userid
WHERE b.userid is null;


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

CREATE TABLE actionlog._action_201409_05 engine = myisam
SELECT userid, uri, time 
FROM actionlog.action_201409_05;

# 主要資料(1) 8月
CREATE TABLE actionlog._forumdetail_click engine = myisam
SELECT * FROM actionlog._action_201408
WHERE userid <> ''
AND date(time) between '2014-08-22' AND '2014-08-31'
AND uri LIKE '%forumdetail%';
# 主要資料(2) 9月
INSERT IGNORE INTO actionlog._forumdetail_click
SELECT * FROM actionlog._action_201409_05
WHERE userid <> ''
AND date(time) between '2014-09-01' AND '2014-09-05'
AND uri LIKE '%forumdetail%';

# 每天有在看文章內頁的人數
SELECT b.d, count(b.userid) as user_count
FROM (
    SELECT a.d, a.userid, count(userid) as c
    FROM (
        SELECT userid, uri, date(time) as d 
        FROM actionlog._forumdetail_click) as a
    GROUP BY a.d, a.userid) as b
GROUP BY b.d;

# 每天各點擊的情況統計(要自行更換以下行為代碼)
SELECT b.d, count(b.userid) as user_count
FROM (
    SELECT a.d, a.userid, a.click, count(userid) as c
    FROM (
        SELECT userid, click, date(log_time) as d
        FROM plsport_playsport.go_top_or_latest_log
        WHERE userid <> ''
        AND click = 'pushit_top' #<-替換這個
         ) as a
    GROUP BY a.d, a.userid, a.click) as b
GROUP BY b.d;

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
WHERE payed = 1 AND type = 1
AND date between '2014-09-09 12:00:00' AND '2014-09-10 11:59:59';

# 儲值噱幣
SELECT sum(amount)
FROM plsport_playsport.pcash_log
WHERE payed = 1 AND type in (3,4)
AND date between '2014-09-09 12:00:00' AND '2014-09-10 11:59:59'
AND amount > 998;

# 購買預測-前後幾天
SELECT a.d, sum(amount) as spent
FROM (
    SELECT userid, amount, date(date) as d
    FROM plsport_playsport.pcash_log
    WHERE payed = 1 AND type = 1
    AND date(date) between '2014-08-31' AND '2014-09-15') as a
GROUP BY a.d;

# 儲值噱幣-前後幾天
SELECT a.d, sum(amount) as spent
FROM (
    SELECT userid, amount, date(date) as d
    FROM plsport_playsport.pcash_log
    WHERE payed = 1 AND type in (3,4)
    AND date(date) between '2014-08-31' AND '2014-09-15') as a
GROUP BY a.d;

# 儲值噱幣
SELECT userid, count(amount) as redeem_count, sum(amount) as redeem_total
FROM plsport_playsport.pcash_log
WHERE payed = 1 AND type in (3,4)
AND amount > 998
AND date between '2014-09-09 12:00:00' AND '2014-09-10 11:59:59'
GROUP BY userid;

CREATE TABLE actionlog.action_201409_activity_php engine = myisam
SELECT * FROM actionlog.action_201409_14
WHERE uri LIKE '%action=buypcash%';

SELECT * FROM actionlog.action_201409_activity_php
ORDER BY id DESC;

CREATE TABLE actionlog.action_201409_activity_php_1 engine = myisam
SELECT userid, uri, time, 
       (case when (locate('FROM=',uri)=0) then '' else substr(uri,locate('FROM=',uri)+5, length(uri)) end) as p
FROM actionlog.action_201409_activity_php;


# 柔雅2014-09-19補充的需求
SELECT a.payway, a.platform_type, sum(a.price) as revenue #收益金額
FROM (
    SELECT userid, CREATEon, ordernumber, price, payway, CREATE_FROM, platform_type 
    FROM plsport_playsport.order_data
    WHERE CREATEon between '2014-09-09 12:00:00' AND '2014-09-10 11:59:59'
    AND sellconfirm = 1
    AND CREATE_FROM = 8) as a
GROUP BY a.payway, a.platform_type;

SELECT a.payway, a.platform_type, count(a.price) as revenue #付款人數
FROM (
    SELECT userid, CREATEon, ordernumber, price, payway, CREATE_FROM, platform_type 
    FROM plsport_playsport.order_data
    WHERE CREATEon between '2014-09-09 12:00:00' AND '2014-09-10 11:59:59'
    AND sellconfirm = 1
    AND CREATE_FROM = 8) as a
GROUP BY a.payway, a.platform_type;


#-----------------------------------------------------
# to EDDY
#
# 麻煩你提供  9/9 12:00-9/10 12:00  與 4/1 0:00-24:00，
# 這兩個時段內的儲值金額分佈，
# 目地:想比較，活動時間不同，是否對活動的成效有影響。
# 煩請在下週大會之前完成，在大會上要報告。
#-----------------------------------------------------

# (1)
CREATE TABLE plsport_playsport._order_data_first_discount engine = myisam
SELECT userid, CREATEon, price 
FROM plsport_playsport.order_data
WHERE payway in (1,2,3,4,5,6,9,10)
AND sellconfirm = 1
AND date(CREATEon) between '2014-03-30' AND '2014-04-05';

CREATE TABLE plsport_playsport._order_data_second_discount engine = myisam
SELECT userid, CREATEon, price 
FROM plsport_playsport.order_data
WHERE payway in (1,2,3,4,5,6,9,10)
AND sellconfirm = 1
AND date(CREATEon) between '2014-09-07' AND '2014-09-13';

SELECT a.d, a.h, sum(a.price) as redeem
FROM (
    SELECT userid, date(CREATEon) as d, hour(CREATEon) as h, price 
    FROM plsport_playsport._order_data_first_discount) a
GROUP BY a.d, a.h;

SELECT a.d, a.h, sum(a.price) as redeem
FROM (
    SELECT userid, date(CREATEon) as d, hour(CREATEon) as h, price 
    FROM plsport_playsport._order_data_second_discount) a
GROUP BY a.d, a.h;

#-----------------------------------------------------
# 5.三個月後，分析有得到優惠的消費者的arpu，是否較沒有得到優惠的使用者高
# (可以參考4/1號的任務)
# http://pm.playsport.cc/index.php/tasksComments?tasksId=3523&projectId=11
#-----------------------------------------------------

CREATE TABLE plsport_playsport._who_use_offer engine = myisam
SELECT a.userid, (case when (a.userid is not null) then 'yes' else '' end) as accept_offer
FROM (
    SELECT userid, CREATEon, price, payway, CREATE_FROM
    FROM plsport_playsport.order_data
    WHERE sellconfirm = 1 AND CREATE_FROM = 8
    AND CREATEon between '2014-09-09 12:00:00' AND '2014-09-10 12:00:00') as a
GROUP BY a.userid;

CREATE TABLE plsport_playsport._everyone engine = myisam
SELECT a.userid
FROM (
    SELECT userid, CREATEon, price, payway, CREATE_FROM
    FROM plsport_playsport.order_data
    WHERE sellconfirm = 1 AND payway in (1,2,3,4,5,6,9)
    AND CREATEon between '2014-09-04 00:00:00' AND '2014-09-15 23:59:59') as a
GROUP BY a.userid;

CREATE TABLE plsport_playsport._who_dont_use_offer engine = myisam
SELECT a.userid, (case when (a.userid is not null) then 'no' else '' end) as accept_offer
FROM plsport_playsport._everyone a LEFT JOIN plsport_playsport._who_use_offer b on a.userid = b.userid
WHERE b.userid is null;

CREATE TABLE plsport_playsport._list_0 engine = myisam
SELECT * FROM plsport_playsport._who_use_offer;
INSERT IGNORE INTO plsport_playsport._list_0 
SELECT * FROM plsport_playsport._who_dont_use_offer;

CREATE TABLE plsport_playsport._full_revenue_0 engine = myisam
SELECT userid, CREATEon, price, payway, CREATE_FROM
FROM plsport_playsport.order_data
WHERE sellconfirm = 1 AND payway in (1,2,3,4,5,6,9)
AND CREATEon between '2014-09-16 00:00:00' AND '2014-12-07 23:59:59';

CREATE TABLE plsport_playsport._full_revenue_1 engine = myisam
SELECT userid, sum(price) as total_redeem
FROM plsport_playsport._full_revenue_0
GROUP BY userid;

CREATE TABLE plsport_playsport._list_1 engine = myisam
SELECT a.userid, b.total_redeem, a.accept_offer 
FROM plsport_playsport._list_0 a LEFT JOIN plsport_playsport._full_revenue_1 b on a.userid = b.userid;


SELECT accept_offer, sum(total_redeem) as all_total_redeem, count(userid) as all_user_count 
FROM plsport_playsport._list_1
GROUP BY accept_offer;


SELECT accept_offer, sum(total_redeem) as all_total_redeem, count(userid) as all_user_count 
FROM plsport_playsport._list_1
WHERE total_redeem is not null
GROUP BY accept_offer;

CREATE TABLE plsport_playsport._list_2 engine = myisam
SELECT * FROM plsport_playsport._list_1
WHERE total_redeem is not null;

SELECT 'userid', 'total_redeem', 'accept_offer' UNION (
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_list_2.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._list_2);



# =================================================================================================
# 任務: 20150401儲值優惠活動:網址參數設定&成效追蹤 [新建]
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4347&projectId=11
# 麻煩協助:1.設定網址參數 2.追蹤這些網址的點擊成效
# 需要設定網址參數的頁面如下(可參考之前的任務):
# 
# 1.彈出式視窗(連接到儲值優惠活動說明頁)
# 2.header(連接到儲值優惠活動說明頁)
# 3.網站banner(連接到儲值優惠活動說明頁)
#      a.事前宣傳用
#         (放置位置:討論區上方、即時比分頁上方、預測賽事上方)
#      b.活動開跑倒數
#           (放置位置:討論區上方、即時比分頁上方、預測賽事上方)
# 4.活動說明頁(連接到購買噱幣頁)
#    a.事前宣傳用:
#          a-1:電腦版
#          a-2:手機版
#    b.活動開跑倒數
#       b-1:電腦版
#       b-2:手機版
# 預計完成時間:3/13
# eddy:
# 麻煩協助分析活動成效，項目如下:
# 1.活動期間的業績總額(總儲值金額)
# 2.活動參與人數
# 3.金額分佈: 每個價格有多少筆數、有多少人購買該價格
# 4.網站廣告點擊成效分析
# 5.三個月後，分析有得到優惠的消費者的arpu，是否較沒有得到優惠的使用者高
# (可以參考9月的任務)
# 
# 先完成1-4項，第5項三個月後再報告
# =================================================================================================

# 活動當日購買預測金額 188840
SELECT sum(amount)
FROM plsport_playsport.pcash_log
WHERE payed = 1 AND type = 1
AND date between '2015-04-01 12:00:00' AND '2015-04-02 11:59:59';


# 動當日儲值噱幣金額 868295
SELECT sum(amount)
FROM plsport_playsport.pcash_log
WHERE payed = 1 AND type in (3,4)
AND date between '2015-04-01 12:00:00' AND '2015-04-02 11:59:59'
AND amount > 998;

# 購買預測-前後幾天
SELECT a.d, sum(amount) as spent
FROM (
    SELECT userid, amount, date(date) as d
    FROM plsport_playsport.pcash_log
    WHERE payed = 1 AND type = 1
    AND date(date) between '2015-03-20' AND '2015-04-10') as a
GROUP BY a.d;

# 儲值噱幣-前後幾天
SELECT a.d, sum(amount) as spent
FROM (
    SELECT userid, amount, date(date) as d
    FROM plsport_playsport.pcash_log
    WHERE payed = 1 AND type in (3,4)
    AND date(date) between '2015-03-20' AND '2015-04-10') as a
GROUP BY a.d;


# 儲值噱幣
SELECT userid, count(amount) as redeem_count, sum(amount) as redeem_total
FROM plsport_playsport.pcash_log
WHERE payed = 1 AND type in (3,4)
AND amount > 998
AND date between '2014-09-09 12:00:00' AND '2014-09-10 11:59:59'
GROUP BY userid;

# 柔雅2014-09-19補充的需求 '2015-04-01 12:00:00' AND '2015-04-02 11:59:59'
SELECT a.payway, a.platform_type, sum(a.price) as revenue #收益金額
FROM (
    SELECT userid, CREATEon, ordernumber, price, payway, CREATE_FROM, (case when (platform_type<2) then 1 else 2 end) as platform_type
    FROM plsport_playsport.order_data
    WHERE CREATEon between '2015-04-01 12:00:00' AND '2015-04-02 11:59:59'
    AND sellconfirm = 1
    AND CREATE_FROM = 8) as a
GROUP BY a.payway, a.platform_type;

SELECT a.payway, a.platform_type, count(a.price) as revenue #付款人數
FROM (
    SELECT userid, CREATEon, ordernumber, price, payway, CREATE_FROM, (case when (platform_type<2) then 1 else 2 end) as platform_type
    FROM plsport_playsport.order_data
    WHERE CREATEon between '2015-04-01 12:00:00' AND '2015-04-02 11:59:59'
    AND sellconfirm = 1
    AND CREATE_FROM = 8) as a
GROUP BY a.payway, a.platform_type;


# 活動頁面的記錄
create table actionlog._buypcashbonus engine = myisam
SELECT userid, uri, time, (case when (platform_type<2) then 'pc' else 'mobile' end) as p
FROM actionlog.action_201503
where uri like '%buypcashbonus%'
and time between '2015-03-01 00:00:00' and '2015-03-31 23:59:59';

create table actionlog._buypcashbonus_1 engine = myisam
select a.userid, a.uri, a.time, a.p, (case when (locate('&', a.lo)=0) then a.lo else (substr(a.lo,1,locate('&', a.lo)-1)) end) as lo
from (
    SELECT userid, uri, time, p, substr(uri,locate('from=', uri)+5, length(uri)) as lo
    FROM actionlog._buypcashbonus) as a;

SELECT lo, p, count(uri) as c 
FROM actionlog._buypcashbonus_1
where substr(lo,1,2) not in ('iv','si')
group by lo, p;

# forum	101
# header	4261
# livescore	1537
# popup	3686
# predictgame	61



# 儲值頁面的記錄
create table actionlog._temp engine = myisam
SELECT * FROM actionlog.action_201504
where uri like '%from=%' and uri like '%buy_pcash_step%';

create table actionlog._buy_pcash_step engine = myisam
SELECT userid, uri, time, (case when (platform_type<2) then 'pc' else 'mobile' end) as p 
FROM actionlog._temp;

create table actionlog._buy_pcash_step_1 engine = myisam
SELECT userid, uri, time, p, substr(uri,locate('from=', uri)+5, length(uri)) as from_where
FROM actionlog._buy_pcash_step;

SELECT from_where, count(uri) as c 
FROM actionlog._buy_pcash_step_1
group by from_where;

# activity_mobile	347
# activity_pc	    218


# update: 2015-07-10
# to 柔雅:    
# 我先押7/14(二)完成此任務, 3Q
# 因為月初我事情忙, 如果有空檔我會提早完成它.
# 2015-06-30 14:01
# Eddy [行銷企劃]
# eddy@playsport.cc
#  TO eddy:
# 7月份到了，要麻煩你進行最後的arpu分析，
# 麻煩在回覆，何時可以產出報告，感謝!

# 有在優惠期間儲值的人
create table plsport_playsport._who_receive_offer engine = myisam
SELECT userid, sum(amount) as redeem
FROM plsport_playsport.pcash_log
WHERE payed = 1 AND type in (3,4)
AND date between '2015-04-01 12:00:00' AND '2015-04-02 11:59:59'
AND amount > 998
group by userid;

# 在優惠期間儲值前後儲值的人
create table plsport_playsport._who_dont_receive_offer engine = myisam
SELECT userid, sum(amount) as redeem
FROM plsport_playsport.pcash_log
WHERE payed = 1 AND type in (3,4)
AND date between '2015-03-21 12:00:00' AND '2015-04-10 11:59:59'
AND amount > 998
group by userid;

create table plsport_playsport._who_dont_receive_offer_1 engine = myisam
SELECT a.userid, a.redeem
FROM plsport_playsport._who_dont_receive_offer a left join plsport_playsport._who_receive_offer b on a.userid = b.userid
where b.userid is null;

# 製作主要名單
create table plsport_playsport._list_1 engine = myisam
SELECT userid, (case when (redeem is not null) then 'received_offer' else '' end) as g 
FROM plsport_playsport._who_receive_offer;
insert ignore into plsport_playsport._list_1
SELECT userid, (case when (redeem is not null) then 'not_received_offer' else '' end) as g 
FROM plsport_playsport._who_dont_receive_offer_1;


create table plsport_playsport._spent engine = myisam
SELECT userid, sum(amount) as redeem, count(amount) as redeem_count
FROM plsport_playsport.pcash_log
WHERE payed = 1 AND type in (3,4)
AND date between '2015-04-12 12:00:00' AND now()
group by userid;

create table plsport_playsport._list_2 engine = myisam
SELECT a.userid, a.g, b.redeem, b.redeem_count
FROM plsport_playsport._list_1 a left join plsport_playsport._spent b on a.userid = b.userid
where b.redeem is not null;

SELECT 'userid', 'g', 'redeem', 'redeem_count' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_list_2.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._list_2);

SELECT g, sum(redeem), count(userid)
FROM plsport_playsport._list_2
group by g;

# not_received_o	4126623	501	8236.772455
# received_offer	2636913	247	10675.76113


















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

CREATE TABLE actionlog.action_201408_forum engine = myisam
SELECT userid, uri, time, platform_type
FROM actionlog.action_201408
WHERE uri LIKE '%forum%';

CREATE TABLE actionlog.action_201409_forum engine = myisam
SELECT userid, uri, time, platform_type
FROM actionlog.action_201409
WHERE uri LIKE '%forum%';

CREATE TABLE actionlog.action_201410_forum engine = myisam
SELECT userid, uri, time, platform_type
FROM actionlog.action_20141012
WHERE uri LIKE '%forum%';


CREATE TABLE actionlog.action_forum engine = myisam
SELECT * 
FROM actionlog.action_201409_forum
WHERE userid <> '';

INSERT IGNORE INTO actionlog.action_forum 
SELECT * FROM actionlog.action_201410_forum
WHERE userid  <> '';

CREATE TABLE actionlog.action_forum_1 engine = myisam
SELECT userid, uri, time, (case when (platform_type<2) then 'pc' else 'mobile' end) as platform_type
FROM actionlog.action_forum
WHERE date(time) between '2014-09-11' AND  '2014-10-12'
AND substr(uri,1,6) = '/forum';

drop TABLE actionlog.action_201408_forum;
drop TABLE actionlog.action_201409_forum;
drop TABLE actionlog.action_201410_forum;
drop TABLE actionlog.action_forum;

# 區間設定在between '2014-08-14' AND  '2014-09-14'

# (1) 討論區pv
CREATE TABLE actionlog.action_forum_pv engine = myisam 
SELECT userid, count(uri) as forum_pv 
FROM actionlog.action_forum_1
GROUP BY userid;

# (2) 討論區使用裝置佔比
CREATE TABLE actionlog.action_forum_device_pv engine = myisam
SELECT a.userid, sum(a.pc) as pc, sum(a.mobile) as mobile
FROM (
    SELECT userid, (case when (platform_type = 'pc') then 1 else 0 end) as pc, 
                   (case when (platform_type = 'mobile') then 1 else 0 end) as mobile
    FROM actionlog.action_forum_1) as a
GROUP BY a.userid;

CREATE TABLE actionlog.action_forum_device_pv_1 engine = myisam
SELECT userid, pc, mobile, round((pc/(pc+mobile)),2) as pc_p, round((mobile/(pc+mobile)),2) as mobile_p
FROM actionlog.action_forum_device_pv;

drop TABLE actionlog.action_forum_device_pv;
rename TABLE actionlog.action_forum_device_pv_1 to actionlog.action_forum_device_pv;

# (3) po文數
CREATE TABLE plsport_playsport._post_count engine = myisam 
SELECT a.postuser as userid, count(a.subjectid) as post
FROM (
    SELECT subjectid, postuser, posttime 
    FROM plsport_playsport.forum
    WHERE date(posttime) between '2014-09-11' AND '2014-10-12') as a
GROUP BY a.postuser;

# (4) 回文數
CREATE TABLE plsport_playsport._reply_count engine = myisam
SELECT userid, count(subjectid) as reply
FROM plsport_playsport.forumcontent
WHERE date(postdate) between '2014-09-11' AND '2014-10-12'
GROUP BY userid;

# (5) 推數
CREATE TABLE plsport_playsport._LIKE_count engine = myisam
SELECT userid, count(subject_id) as LIKE_c
FROM plsport_playsport.forum_LIKE
WHERE date(CREATE_date) between '2014-09-11' AND '2014-10-12'
GROUP BY userid;

# (6) 最後一次登入
CREATE TABLE plsport_playsport._last_time_login engine = myisam
SELECT userid, date(max(signin_time)) as last_time_login
FROM plsport_playsport.member_signin_log_archive
GROUP BY userid;

# (7) 居住地
# 找code line 1708: _city_info_ok_with_chinese

    ALTER TABLE actionlog.action_forum_pv CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
    ALTER TABLE actionlog.action_forum_device_pv CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
    ALTER TABLE plsport_playsport._LIKE_count CHANGE `userid` `userid` CHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
    ALTER TABLE plsport_playsport._reply_count CHANGE `userid` `userid` CHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

    ALTER TABLE actionlog.action_forum_pv ADD INDEX (`userid`);
    ALTER TABLE actionlog.action_forum_device_pv ADD INDEX (`userid`);
    ALTER TABLE plsport_playsport._post_count ADD INDEX (`userid`);
    ALTER TABLE plsport_playsport._reply_count ADD INDEX (`userid`);
    ALTER TABLE plsport_playsport._LIKE_count ADD INDEX (`userid`);
    ALTER TABLE plsport_playsport._last_time_login ADD INDEX (`userid`);


CREATE TABLE plsport_playsport._list_1 engine = myisam
SELECT c.userid, c.nickname, c.forum_pv, d.pc, d.mobile, d.pc_p, d.mobile
FROM (
    SELECT a.userid, b.nickname, a.forum_pv
    FROM actionlog.action_forum_pv a LEFT JOIN plsport_playsport.member b on a.userid = b.userid) as c
    LEFT JOIN actionlog.action_forum_device_pv as d on c.userid = d.userid;

CREATE TABLE plsport_playsport._list_2 engine = myisam
SELECT a.userid, a.nickname, b.g, a.forum_pv, a.pc, a.mobile, a.pc_p, a.mobile_p
FROM plsport_playsport._list_1 a LEFT JOIN user_cluster.cluster_with_real_userid b on a.userid = b.userid;

    ALTER TABLE plsport_playsport._list_2 ADD INDEX (`userid`);

CREATE TABLE plsport_playsport._list_3 engine = myisam
SELECT a.userid, a.nickname, a.g, a.forum_pv, a.pc, a.mobile, a.pc_p, a.mobile_p, b.last_time_login
FROM plsport_playsport._list_2 a LEFT JOIN plsport_playsport._last_time_login b on a.userid = b.userid;

    ALTER TABLE plsport_playsport._list_3 ADD INDEX (`userid`);
    ALTER TABLE plsport_playsport._city_info_ok_with_chinese ADD INDEX (`userid`);

CREATE TABLE plsport_playsport._list_4 engine = myisam
SELECT a.userid, a.nickname, a.g, a.forum_pv, a.pc, a.mobile, a.pc_p, a.mobile_p, a.last_time_login, b.city1
FROM plsport_playsport._list_3 a LEFT JOIN plsport_playsport._city_info_ok_with_chinese b on a.userid = b.userid;


CREATE TABLE plsport_playsport._list_5 engine = myisam
SELECT a.userid, a.nickname, a.g, a.forum_pv, a.pc, a.mobile, a.pc_p, a.mobile_p, a.last_time_login, a.city1, b.post 
FROM plsport_playsport._list_4 a LEFT JOIN plsport_playsport._post_count b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_6 engine = myisam
SELECT a.userid, a.nickname, a.g, a.forum_pv, a.pc, a.mobile, a.pc_p, a.mobile_p, a.last_time_login, a.city1, a.post, b.reply
FROM plsport_playsport._list_5 a LEFT JOIN plsport_playsport._reply_count b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_7 engine = myisam
SELECT a.userid, a.nickname, a.g, a.forum_pv, a.pc, a.mobile, a.pc_p, a.mobile_p, a.last_time_login, a.city1, a.post, a.reply, b.LIKE_c
FROM plsport_playsport._list_6 a LEFT JOIN plsport_playsport._LIKE_count b on a.userid = b.userid;

drop TABLE plsport_playsport._list_1, plsport_playsport._list_2, plsport_playsport._list_3;
drop TABLE plsport_playsport._list_4, plsport_playsport._list_5, plsport_playsport._list_6;

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

CREATE TABLE plsport_playsport._forum engine = myisam
SELECT subjectid, allianceid, postuser, posttime, year(posttime) as y, replycount, pushcount 
FROM plsport_playsport.forum
WHERE allianceid in (1,2,3,4,6,9,91)
ORDER BY posttime DESC;

SELECT y, allianceid, count(subjectid) as post_count
FROM plsport_playsport._forum
WHERE y >2012
GROUP BY y, allianceid;

SELECT y, allianceid, count(subjectid) as post_count
FROM plsport_playsport._forum
WHERE y > 2012
AND pushcount > 35
GROUP BY y, allianceid;


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

CREATE TABLE plsport_playsport._forum engine = myisam
SELECT subjectid, allianceid, gametype, postuser, posttime, replycount, pushcount
FROM plsport_playsport.forum
WHERE date(posttime) between '2013-09-13' AND '2014-09-15'
ORDER BY posttime DESC;

        CREATE TABLE plsport_playsport._forum engine = myisam
        SELECT subjectid, allianceid, gametype, postuser, posttime, replycount, pushcount
        FROM plsport_playsport.forum
        WHERE date(posttime) between '2014-08-15' AND '2014-09-15'
        ORDER BY posttime DESC;

# 回文數的分佈
CREATE TABLE plsport_playsport._forum_replycount_one_month engine = myisam
SELECT replycount, count(subjectid) as c 
FROM plsport_playsport._forum
GROUP BY replycount;

# 推文數的分佈
CREATE TABLE plsport_playsport._forum_pushocunt_one_month engine = myisam
SELECT pushcount, count(subjectid) as c 
FROM plsport_playsport._forum
GROUP BY pushcount;

    SELECT 'pushcount', 'c' UNION (
    SELECT * 
    INTO outfile 'C:/Users/1-7_ASUS/Desktop/_forum_pushocunt_one_month.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._forum_pushocunt_one_month);

    SELECT 'pushcount', 'c' UNION (
    SELECT * 
    INTO outfile 'C:/Users/1-7_ASUS/Desktop/_forum_pushocunt_one_year.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._forum_pushocunt_one_year);

    SELECT 'replycount', 'c' UNION (
    SELECT * 
    INTO outfile 'C:/Users/1-7_ASUS/Desktop/_forum_replycount_one_month.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._forum_replycount_one_month);

    SELECT 'replycount', 'c' UNION (
    SELECT * 
    INTO outfile 'C:/Users/1-7_ASUS/Desktop/_forum_replycount_one_year.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._forum_replycount_one_year);

# (學文)
# 分析文的篇數是捉forum裡的gametype=1
# 最讚分析文是analysis_king
# 優質分析王是honorboard的honortype=5 (另外, 條件也是上月入選過12次最讚分析文, 當月就會當選優質分析王)

CREATE TABLE plsport_playsport._forum_alltime_analysis_post engine = myisam
SELECT subjectid, allianceid, gametype, postuser, posttime, replycount, pushcount 
FROM plsport_playsport.forum
WHERE gametype = 1;

# (1)分析文的篇數人數分佈 - 此表之後再自已匯出.csv
CREATE TABLE plsport_playsport._forum_alltime_analysis_post_user engine = myisam
SELECT postuser, count(subjectid) as c 
FROM plsport_playsport._forum_alltime_analysis_post
WHERE postuser <> ''
GROUP BY postuser;

# (2)最讚分析文統計
CREATE TABLE plsport_playsport._analysis_king_count engine = myisam
SELECT userid, count(subjectid) as c
FROM plsport_playsport.analysis_king
GROUP BY userid;

# (3)優質分析王統計
CREATE TABLE plsport_playsport._permuin_analysis_king_count engine = myisam
SELECT userid, count(id) as c
FROM plsport_playsport.honorboard
WHERE honortype = 5 #榮玉榜的記錄
GROUP BY userid;

# (4)亮單文統計
CREATE TABLE plsport_playsport._forum_alltime_showoff_post engine = myisam
SELECT a.postuser, count(a.subjectid) as c
FROM (
    SELECT subjectid, allianceid, gametype, postuser, posttime, replycount, pushcount 
    FROM plsport_playsport.forum
    WHERE gametype = 3) as a #亮單文
GROUP BY a.postuser;

# (5)Live文統計
CREATE TABLE plsport_playsport._forum_alltime_live_post engine = myisam
SELECT a.postuser, count(a.subjectid) as c
FROM (
    SELECT subjectid, allianceid, gametype, postuser, posttime, replycount, pushcount 
    FROM plsport_playsport.forum
    WHERE gametype = 2) as a #Live文
GROUP BY a.postuser;

CREATE TABLE plsport_playsport._forum_alltime_post engine = myisam
SELECT postuser, count(subjectid) as c 
FROM plsport_playsport._forum
GROUP BY postuser;


# 任務: 討論區升級數據 [新建] 2014-09-26 補充 (學文)
# to eddy
# 1.表a 近一年的回文數分布，轉換成人數(暫不做) (依原來做法改成1個月的)
# 2.表b 近一年的推文數分布，轉換成人數(暫不做) (依原來做法改成1個月的)
# 3.回文數(不用做) 、推文數(不用做)、貼文數、亮單文數、live文數，資料區間抓近一個月(用forum做, 依文章列表的資訊做的)
# 4.一個人會去按別人推的推數分布，近一個月(用forumcontent做, 依個人的行為) done
# 5.一個人會去回覆文章的回覆數分布，近一個月(用forum_LIKE做, 依個人的行為) done 
# ps.　( 第345點，也都是以人數（非文章篇數）的方式呈現）

# _forumcontent
# _forum_LIKE
# 以上2個表已經篩好區間'2013-09-13' AND '2014-09-15'

CREATE TABLE plsport_playsport._forumcontent engine = myisam
SELECT subjectid, userid, postdate 
FROM plsport_playsport.forumcontent;

CREATE TABLE plsport_playsport._forum_LIKE engine = myisam
SELECT subject_id, userid, CREATE_date 
FROM plsport_playsport.forum_LIKE;

CREATE TABLE plsport_playsport._reply_count_list engine = myisam
SELECT userid, count(subjectid) as reply_count 
FROM plsport_playsport._forumcontent
GROUP BY userid;

CREATE TABLE plsport_playsport._LIKE_count_list engine = myisam
SELECT userid, count(subject_id) as LIKE_count 
FROM plsport_playsport._forum_LIKE
GROUP BY userid;

    SELECT 'userid', 'reply_count' UNION (
    SELECT * 
    INTO outfile 'C:/Users/1-7_ASUS/Desktop/_reply_count_list.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._reply_count_list);

    SELECT 'userid', 'LIKE_count' UNION (
    SELECT * 
    INTO outfile 'C:/Users/1-7_ASUS/Desktop/_LIKE_count_list.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._LIKE_count_list);

CREATE TABLE plsport_playsport._forum engine = myisam
SELECT * FROM plsport_playsport.forum
WHERE date(postTime) between '2014-08-15' AND '2014-09-15';

CREATE TABLE plsport_playsport._forumcontent engine = myisam
SELECT * FROM plsport_playsport.forumcontent
WHERE date(postdate) between '2014-08-15' AND '2014-09-15';

CREATE TABLE plsport_playsport._forum_LIKE engine = myisam
SELECT * FROM plsport_playsport.forum_LIKE
WHERE date(CREATE_date) between '2014-08-15' AND '2014-09-15';


# 貼文
CREATE TABLE plsport_playsport._forum_1_post_user engine = myisam
SELECT postuser, count(subjectid) as c
FROM plsport_playsport._forum
GROUP BY postuser;

# 亮單文
CREATE TABLE plsport_playsport._forum_1_showoff_user engine = myisam
SELECT postuser, count(subjectid) as c 
FROM plsport_playsport._forum
WHERE gametype = 3
GROUP BY postuser;

# Live文
CREATE TABLE plsport_playsport._forum_1_live_user engine = myisam
SELECT postuser, count(subjectid) as c 
FROM plsport_playsport._forum
WHERE gametype = 2
GROUP BY postuser;


    SELECT 'postuser', 'c' UNION (
    SELECT * 
    INTO outfile 'C:/Users/1-7_ASUS/Desktop/_forum_1_post_user.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._forum_1_post_user);

    SELECT 'postuser', 'c' UNION (
    SELECT * 
    INTO outfile 'C:/Users/1-7_ASUS/Desktop/_forum_1_showoff_user.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._forum_1_showoff_user);

    SELECT 'postuser', 'c' UNION (
    SELECT * 
    INTO outfile 'C:/Users/1-7_ASUS/Desktop/_forum_1_live_user.csv' 
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
CREATE TABLE plsport_playsport._list_1 engine = myisam
SELECT (b.id%20)+1 as g, a.buyerid, a.buy_date, a.buy_price, a.position
FROM (
    SELECT buyerid, buy_date, buy_price, position 
    FROM plsport_playsport._predict_buyer_with_cons
    WHERE date(buy_date) between '2014-09-03' AND '2014-09-28') as a LEFT JOIN plsport_playsport.member b on a.buyerid = b.userid
WHERE substr(a.position,1,3) = 'BRC'; #購買後推廌專區

# 分出實驗組和對照組
CREATE TABLE plsport_playsport._list_2 engine = myisam
SELECT (case when (g in (8,9,10,11,12,13,14)) then 'a' else 'b' end) as g, buyerid, buy_date, buy_price, position 
FROM plsport_playsport._list_1;

# 購買後推廌專區 - 各位置的收益
SELECT g, position, sum(buy_price) as revenue 
FROM plsport_playsport._list_2
GROUP BY g, position;

# 誰在購買後推廌專區消費
CREATE TABLE plsport_playsport._list_3_who_buy_brc engine = myisam
SELECT g, buyerid as userid, sum(buy_price) as BRC_revenue 
FROM plsport_playsport._list_2
GROUP BY g, buyerid;

# 所有人的消費
CREATE TABLE plsport_playsport._list_3_everyone_buy engine = myisam
SELECT buyerid, buy_date, sum(buy_price) as revenue 
FROM plsport_playsport._predict_buyer_with_cons
WHERE date(buy_date) between '2014-09-03' AND '2014-09-28'
GROUP BY buyerid;

# 在購買後推廌專區消費的人的所有消費_最後名單
CREATE TABLE plsport_playsport._list_4 engine = myisam
SELECT a.g as abtest, a.userid, a.BRC_revenue, b.revenue 
FROM plsport_playsport._list_3_who_buy_brc a LEFT JOIN plsport_playsport._list_3_everyone_buy b on a.userid = b.buyerid;

# 撈出所有brc的點擊log
CREATE TABLE actionlog.action_201409_28_rp_brc engine = myisam
SELECT userid, uri, time 
FROM actionlog.action_201409_28
WHERE date(time) between '2014-09-03' AND '2014-09-28'
AND userid <> ''
AND uri LIKE '%rp=BRC%';

CREATE TABLE actionlog.action_201409_28_rp_brc_1 engine = myisam
SELECT userid, uri, time, substr(uri,locate('&rp=',uri)+4,length(uri)) as p
FROM actionlog.action_201409_28_rp_brc;

ALTER TABLE `action_201409_28_rp_brc_1` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

CREATE TABLE actionlog.action_201409_28_rp_brc_2 engine = myisam
SELECT (b.id%20)+1 as g, a.userid, a.uri, a.time, a.p
FROM actionlog.action_201409_28_rp_brc_1 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

CREATE TABLE actionlog.action_201409_28_rp_brc_3 engine = myisam
SELECT (case when (g in (8,9,10,11,12,13,14)) then 'a' else 'b' end) as g, userid, uri, time , p
FROM actionlog.action_201409_28_rp_brc_2;

SELECT g, p, count(userid) as c 
FROM actionlog.action_201409_28_rp_brc_3
GROUP BY g, p;


# =================================================================================================
# 麻煩你協助撈取，2014年目前達到以下儲值金額，的人數有多少人: (柔雅) 2014-09-29
# 
# 1. 一萬5千元
# 2. 2萬、3萬、4萬、5萬、6萬、7萬、8萬、9萬、10萬
# 3.12萬、13萬、15萬
# 4.2014目前99.9%，那7個人的各別儲值金額
# =================================================================================================

CREATE TABLE plsport_playsport._order_data_2014 engine = myisam
SELECT userid, CREATEon, price
FROM plsport_playsport.order_data
WHERE payway in (1,2,3,4,5,6,9,10)
AND sellconfirm = 1
AND year(CREATEon) = 2014;

CREATE TABLE plsport_playsport._order_data_2014_1 engine = myisam
SELECT userid, sum(price) as total_redeem 
FROM plsport_playsport._order_data_2014
GROUP BY userid;

SELECT count(userid)
FROM plsport_playsport._order_data_2014_1
WHERE total_redeem >= 150000 ; # 一直更換此數字就可以了

SELECT a.d, a.h, sum(a.price) as redeem
FROM (
    SELECT userid, date(CREATEon) as d, hour(CREATEon) as h, price 
    FROM plsport_playsport._order_data_first_discount) a
GROUP BY a.d, a.h;

SELECT a.h, sum(a.price) as redeem
FROM (
    SELECT userid, date(CREATEon) as d, hour(CREATEon) as h, price 
    FROM plsport_playsport.order_data
    WHERE payway in (1,2,3,4,5,6,9,10)
    AND sellconfirm = 1
    AND date(CREATEon) between '2014-08-01' AND '2014-09-28') as a
GROUP BY a.h;


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

CREATE TABLE plsport_playsport._predict_buyer_with_cons_edited engine = myisam
SELECT buyerid, buy_date, buy_price, position 
FROM plsport_playsport._predict_buyer_with_cons
WHERE buy_date between '2014-09-15 15:00:00' AND '2014-10-08 23:59:59';

CREATE TABLE plsport_playsport._predict_buyer_with_cons_edited_1 engine = myisam
SELECT (b.id%20)+1 as g, a.buyerid, a.buy_date, a.buy_price, a.position 
FROM plsport_playsport._predict_buyer_with_cons_edited a LEFT JOIN plsport_playsport.member b on a.buyerid = b.userid;

CREATE TABLE plsport_playsport._predict_buyer_with_cons_edited_2 engine = myisam
SELECT (case when (g>14) then 'a' else 'b' end) as abtest, buyerid as userid, buy_date, buy_price, position
FROM plsport_playsport._predict_buyer_with_cons_edited_1;

CREATE TABLE plsport_playsport._predict_buyer_with_cons_edited_3 engine = myisam
SELECT a.abtest, a.userid, a.buy_date, a.buy_price, a.position, a.p
FROM (
    SELECT abtest, userid, buy_date, buy_price, position, substr(position,1,5) as p
    FROM plsport_playsport._predict_buyer_with_cons_edited_2) as a
WHERE a.p in ('BZ_MF','BZ_SK');

CREATE TABLE plsport_playsport._list_1 engine = myisam
SELECT abtest, userid, sum(buy_price) as spent 
FROM plsport_playsport._predict_buyer_with_cons_edited_3
GROUP BY abtest, userid;

CREATE TABLE plsport_playsport._list_1_1 engine = myisam
SELECT userid, sum(buy_price) as all_spent 
FROM plsport_playsport._predict_buyer_with_cons_edited_2
GROUP BY userid;

CREATE TABLE plsport_playsport._list_2 engine = myisam
SELECT a.abtest, a.userid, a.spent, b.all_spent 
FROM plsport_playsport._list_1 a LEFT JOIN plsport_playsport._list_1_1 b on a.userid = b.userid;

    SELECT 'abtest', 'userid', 'spent', 'all_spent' UNION (
    SELECT * 
    INTO outfile 'C:/Users/1-7_ASUS/Desktop/_list_2.csv' 
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

CREATE TABLE actionlog._actionlog_livescore engine = myisam 
SELECT userid, uri, time, platform_type 
FROM actionlog.action_20141012
WHERE date(time) between '2014-10-05' AND '2014-10-12'
AND uri LIKE '%/livescore.php%'
AND userid <> '';

CREATE TABLE actionlog._actionlog_livescore_1 engine = myisam
SELECT a.userid, a.uri, (case when (locate('&',a.p)=0) then a.p
                              else substr(a.p,1,locate('&',a.p)-1) end) as p, a.time, a.platform_type
FROM (
    SELECT userid, uri, substr(uri,locate('aid',uri)+4,length(uri)) as p, time, platform_type 
    FROM actionlog._actionlog_livescore) as a;

CREATE TABLE actionlog._actionlog_livescore_2 engine = myisam
SELECT userid, uri, (case when (p in ('1#','vescore.php')) then 1 else p end) as p, time, 
                    (case when (platform_type < 2) then 'desktop' else 'mobile' end) as platform 
FROM actionlog._actionlog_livescore_1;

CREATE TABLE actionlog._actionlog_livescore_3 engine = myisam
SELECT a.userid, a.uri, b.alliancename, a.time, a.platform 
FROM actionlog._actionlog_livescore_2 a LEFT JOIN plsport_playsport.alliance b on a.p = b.allianceid;

# (1)看即時比分的天數
CREATE TABLE actionlog._actionlog_livescore_3_usage_daycount_all engine = myisam
SELECT b.userid, count(b.d) as d_count_all
FROM (
    SELECT a.userid, a.d, count(userid) as c
    FROM (
        SELECT userid, uri, alliancename as alli_name, date(time) as d, platform 
        FROM actionlog._actionlog_livescore_3) as a
    GROUP BY a.userid, a.d) as b
GROUP BY b.userid;

# (2)看即時比分的天數-NBA
CREATE TABLE actionlog._actionlog_livescore_3_usage_daycount_nba engine = myisam
SELECT b.userid, count(b.d) as d_count_nba
FROM (
    SELECT a.userid, a.d, count(a.userid ) as c
    FROM (
        SELECT userid, alliancename, date(time) as d 
        FROM actionlog._actionlog_livescore_3
        WHERE alliancename = 'NBA') as a
    GROUP BY a.userid, a.d) as b
GROUP BY b.userid;

# (3)看即時比分的天數-MLB
CREATE TABLE actionlog._actionlog_livescore_3_usage_daycount_mlb engine = myisam
SELECT b.userid, count(b.d) as d_count_mlb
FROM (
    SELECT a.userid, a.d, count(a.userid) as c
    FROM (
        SELECT userid, alliancename, date(time) as d 
        FROM actionlog._actionlog_livescore_3
        WHERE alliancename = 'MLB') as a
    GROUP BY a.userid, a.d) as b
GROUP BY b.userid;

# (4)使用裝置的比例
CREATE TABLE actionlog._actionlog_livescore_3_pv_precentage engine = myisam
SELECT c.userid, c.desktop_pv, c.mobile_pv, round((c.desktop_pv/(c.desktop_pv+c.mobile_pv)),3) as desktop_p,
                                            round((c.mobile_pv/(c.desktop_pv+c.mobile_pv)),3) as mobile_p
FROM (
    SELECT b.userid, sum(b.desktop_pv) as desktop_pv, sum(b.mobile_pv) as mobile_pv
    FROM (
        SELECT a.userid, (case when (a.platform='desktop') then c else 0 end) as desktop_pv,
                         (case when (a.platform='mobile')  then c else 0 end) as mobile_pv
        FROM (
            SELECT userid, platform, count(userid) as c 
            FROM actionlog._actionlog_livescore_3
            GROUP BY userid, platform) as a) as b
    GROUP BY b.userid) as c;

CREATE TABLE actionlog._actionlog_livescore_3_nba_pv engine = myisam
SELECT userid, count(userid) as nba_pv
FROM actionlog._actionlog_livescore_3
WHERE alliancename = 'NBA'
GROUP BY userid;

        ALTER TABLE `_actionlog_livescore_3_nba_pv` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

CREATE TABLE actionlog._actionlog_livescore_3_mlb_pv engine = myisam
SELECT userid, count(userid) as mlb_pv
FROM actionlog._actionlog_livescore_3
WHERE alliancename = 'MLB'
GROUP BY userid;

        ALTER TABLE `_actionlog_livescore_3_mlb_pv` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

CREATE TABLE plsport_playsport._list_1 engine = myisam
SELECT c.userid, c.d_count_all, c.d_count_nba, d.d_count_mlb
FROM (
    SELECT a.userid, a.d_count_all, b.d_count_nba
    FROM actionlog._actionlog_livescore_3_usage_daycount_all a LEFT JOIN actionlog._actionlog_livescore_3_usage_daycount_nba b on a.userid = b.userid) as c
    LEFT JOIN actionlog._actionlog_livescore_3_usage_daycount_mlb as d on c.userid = d.userid;

        ALTER TABLE `_list_1` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

CREATE TABLE plsport_playsport._list_2 engine = myisam
SELECT a.userid, b.nickname, a.d_count_all, a.d_count_nba, a.d_count_mlb 
FROM plsport_playsport._list_1 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

        ALTER TABLE `_actionlog_livescore_3_pv_precentage` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

CREATE TABLE plsport_playsport._list_3 engine = myisam
SELECT a.userid, a.nickname, a.d_count_all, a.d_count_nba, a.d_count_mlb, b.desktop_pv, b.mobile_pv, b.desktop_p, b.mobile_p
FROM plsport_playsport._list_2 a LEFT JOIN actionlog._actionlog_livescore_3_pv_precentage b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_4 engine = myisam
SELECT a.userid, a.nickname, a.d_count_all, a.d_count_nba, a.d_count_mlb, b.nba_pv, a.desktop_pv, a.mobile_pv, a.desktop_p, a.mobile_p 
FROM plsport_playsport._list_3 a LEFT JOIN actionlog._actionlog_livescore_3_nba_pv b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_5 engine = myisam
SELECT a.userid, a.nickname, a.d_count_all, a.d_count_nba, a.d_count_mlb, a.nba_pv, a.desktop_pv, a.mobile_pv, a.desktop_p, a.mobile_p, 
       (case when (b.write_time is not null) then 'yes' else '' end) as anwsered
FROM plsport_playsport._list_4 a LEFT JOIN plsport_playsport.questionnaire_livescoretemplate_answer b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_6 engine = myisam
SELECT a.userid, a.nickname, a.d_count_all, a.d_count_nba, a.d_count_mlb, a.nba_pv, b.mlb_pv, a.desktop_pv, a.mobile_pv, a.desktop_p, a.mobile_p, a.anwsered 
FROM plsport_playsport._list_5 a LEFT JOIN actionlog._actionlog_livescore_3_mlb_pv b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_7 engine = myisam
SELECT * FROM plsport_playsport._list_6
WHERE nba_pv > 5;

# 最後名單
    SELECT 'userid', 'nickname', 'd_count_all', 'd_count_nba', 'd_count_mlb', 'nba_pv', 'mlb_pv', 'desktop_pv', 'mobile_pv', 'desktop_p', 'mobile_p', 'anwsered' UNION (
    SELECT * 
    INTO outfile 'C:/Users/1-7_ASUS/Desktop/_list_7.csv' 
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
ORDER BY id DESC;
# 看起來go_top_or_latest_log已經沒有在運作了, 最後一天到9月2日
# 2014-10-14下午已經又打開了

CREATE TABLE plsport_playsport._go_top_or_latest_log engine = myisam
SELECT * FROM plsport_playsport.go_top_or_latest_log
WHERE month(log_time) = 10 ; # 只檢查10月份的

# 檢查表 (實驗組為: 1,2,3,4,5,6,7,8,9,10)
SELECT c.g, c.click, count(c.userid) as c
FROM (
    SELECT (b.id%20)+1 as g, a.userid, a.click, a.log_time 
    FROM plsport_playsport._go_top_or_latest_log a LEFT JOIN plsport_playsport.member b on a.userid = b.userid) as c
GROUP BY c.g, c.click;
# ---------------------------------------------------------------------

# abtesting報告 2014-11-03

CREATE TABLE plsport_playsport._go_top_or_latest_log engine = myisam
SELECT * 
FROM plsport_playsport.go_top_or_latest_log
WHERE date(log_time) between '2014-10-13' AND '2014-10-23'
ORDER BY id ;

CREATE TABLE plsport_playsport._go_top_or_latest_log_1 engine = myisam
SELECT userid, click, count(userid) as click_count 
FROM plsport_playsport._go_top_or_latest_log
GROUP BY userid, click;

CREATE TABLE plsport_playsport._go_top_or_latest_log_2 engine = myisam
SELECT (case when (c.g<11) then 'a' else 'b' end) as abtest, c.userid, c.click, c.click_count
FROM (
    SELECT (b.id%20)+1 as g, a.userid, a.click, a.click_count
    FROM plsport_playsport._go_top_or_latest_log_1 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid) as c;

# 查詢按推的人數
SELECT abtest, click, sum(click_count)  
FROM plsport_playsport._go_top_or_latest_log_2
GROUP BY abtest, click;

SELECT a.abtest, count(a.userid) as c
FROM (
    SELECT abtest, userid, count(click) as c 
    FROM plsport_playsport._go_top_or_latest_log_2
    GROUP BY abtest, userid) as a
GROUP BY a.abtest;

CREATE TABLE plsport_playsport._go_top_or_latest_log_3 engine = myisam
SELECT abtest, userid, sum(click_count) as c   
FROM plsport_playsport._go_top_or_latest_log_2
GROUP BY abtest, userid;

# 輸出txt給R作abtesting
SELECT 'abtest', 'userid', 'c' UNION (
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_go_top_or_latest_log_3.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._go_top_or_latest_log_3);


        CREATE TABLE actionlog._forumdetail engine = myisam
        SELECT userid, uri, time
        FROM actionlog.action_20141025
        WHERE uri LIKE '%forumdetail.php%'
        AND time between '2014-10-14 14:32:53' AND '2014-10-23 10:00:00'
        AND userid <> '';

        CREATE TABLE actionlog._forumdetail_1 engine = myisam
        SELECT userid, count(uri) as c 
        FROM actionlog._forumdetail
        GROUP BY userid;

        ALTER TABLE `_forumdetail_1` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

        CREATE TABLE actionlog._forumdetail_2 engine = myisam
        SELECT (b.id%20)+1 as g, a.userid, a.c
        FROM actionlog._forumdetail_1 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

        CREATE TABLE actionlog._forumdetail_3 engine = myisam
        SELECT (case when (g<11) then 'a' else 'b' end) as abtest, userid, c 
        FROM actionlog._forumdetail_2;

        SELECT abtest, count(userid) as c
        FROM actionlog._forumdetail_3
        GROUP BY abtest;


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

CREATE TABLE actionlog._actionlog_livescore engine = myisam 
SELECT userid, uri, time, platform_type FROM actionlog.action_201401 WHERE uri LIKE '%/livescore.php%' AND userid <> '';

INSERT IGNORE INTO actionlog._actionlog_livescore SELECT userid, uri, time, platform_type FROM actionlog.action_201402 WHERE uri LIKE '%/livescore.php%' AND userid <> '';
INSERT IGNORE INTO actionlog._actionlog_livescore SELECT userid, uri, time, platform_type FROM actionlog.action_201403 WHERE uri LIKE '%/livescore.php%' AND userid <> '';
INSERT IGNORE INTO actionlog._actionlog_livescore SELECT userid, uri, time, platform_type FROM actionlog.action_201404 WHERE uri LIKE '%/livescore.php%' AND userid <> '';
INSERT IGNORE INTO actionlog._actionlog_livescore SELECT userid, uri, time, platform_type FROM actionlog.action_201405 WHERE uri LIKE '%/livescore.php%' AND userid <> '';
INSERT IGNORE INTO actionlog._actionlog_livescore SELECT userid, uri, time, platform_type FROM actionlog.action_201406 WHERE uri LIKE '%/livescore.php%' AND userid <> '';
INSERT IGNORE INTO actionlog._actionlog_livescore SELECT userid, uri, time, platform_type FROM actionlog.action_201407 WHERE uri LIKE '%/livescore.php%' AND userid <> '';
INSERT IGNORE INTO actionlog._actionlog_livescore SELECT userid, uri, time, platform_type FROM actionlog.action_201408 WHERE uri LIKE '%/livescore.php%' AND userid <> '';
INSERT IGNORE INTO actionlog._actionlog_livescore SELECT userid, uri, time, platform_type FROM actionlog.action_201409 WHERE uri LIKE '%/livescore.php%' AND userid <> '';
INSERT IGNORE INTO actionlog._actionlog_livescore SELECT userid, uri, time, platform_type FROM actionlog.action_20141012 WHERE uri LIKE '%/livescore.php%' AND userid <> '';

CREATE TABLE actionlog._actionlog_livescore_1 engine = myisam
SELECT a.userid, a.uri, (case when (locate('&',a.p)=0) then a.p
                              else substr(a.p,1,locate('&',a.p)-1) end) as p, a.time, a.platform_type
FROM (
    SELECT userid, uri, substr(uri,locate('aid',uri)+4,length(uri)) as p, time, platform_type 
    FROM actionlog._actionlog_livescore) as a;

CREATE TABLE actionlog._actionlog_livescore_2 engine = myisam
SELECT userid, uri, (case when (p in ('1#','vescore.php')) then 1 else p end) as p, time, 
                    (case when (platform_type < 2) then 'desktop' else 'mobile' end) as platform 
FROM actionlog._actionlog_livescore_1;

CREATE TABLE actionlog._actionlog_livescore_watch_nba_day_count engine = myisam
SELECT b.userid, count(b.d) as watch_nba_day_count
FROM (
    SELECT a.userid, a.d, count(a.userid) as c
    FROM (
        SELECT userid, date(time) as d
        FROM actionlog._actionlog_livescore_2
        WHERE p = 3) as a # NBA
    GROUP BY a.userid, a.d) as b
GROUP BY b.userid;

CREATE TABLE actionlog._actionlog_livescore_watch_mlb_day_count engine = myisam
SELECT b.userid, count(b.d) as watch_mlb_day_count
FROM (
    SELECT a.userid, a.d, count(a.userid) as c
    FROM (
        SELECT userid, date(time) as d
        FROM actionlog._actionlog_livescore_2
        WHERE month(time) in (6,7,8,9) # 今年6~9月
        AND p = 1) as a # MLB
    GROUP BY a.userid, a.d) as b
GROUP BY b.userid;

CREATE TABLE plsport_playsport._question_answer engine = myisam
SELECT userid, write_time as t, spend_minute as mins, question01 as q1, question02 as q2, question03 as q3, question04 as q4
FROM plsport_playsport.questionnaire_livescoretemplate_answer
ORDER BY write_time DESC;

CREATE TABLE plsport_playsport._question_answer_1 engine = myisam
SELECT c.userid, c.t, c.mins, c.q1, c.q2, c.q3, c.q4, c.watch_nba_day_count, d.watch_mlb_day_count
FROM (
    SELECT a.userid, a.t, a.mins, a.q1, a.q2, a.q3, a.q4, b.watch_nba_day_count
    FROM plsport_playsport._question_answer a LEFT JOIN actionlog._actionlog_livescore_watch_nba_day_count b on a.userid = b.userid) as c
    LEFT JOIN actionlog._actionlog_livescore_watch_mlb_day_count as d on c.userid = d.userid;

CREATE TABLE plsport_playsport._question_answer_2 engine = myisam
SELECT userid, t, mins, q1,
                       (case when (q1 LIKE '%1%') then 1 else 0 end) as a1, 
                       (case when (q1 LIKE '%2%') then 1 else 0 end) as a2,
                       (case when (q1 LIKE '%3%') then 1 else 0 end) as a3,
                       (case when (q1 LIKE '%4%') then 1 else 0 end) as a4,
                       (case when (q1 LIKE '%5%') then 1 else 0 end) as a5,
                        q2, q3,
                       (case when (q3 LIKE '%1%') then 1 else 0 end) as b1, 
                       (case when (q3 LIKE '%2%') then 1 else 0 end) as b2, 
                       (case when (q3 LIKE '%3%') then 1 else 0 end) as b3,
                       q4, watch_nba_day_count, watch_mlb_day_count 
FROM plsport_playsport._question_answer_1;

        update plsport_playsport._question_answer_2 SET q2 = TRIM(TRAILING '\\' FROM q2);
        update plsport_playsport._question_answer_2 SET q2 = TRIM(TRAILING ' ' FROM q2);
        update plsport_playsport._question_answer_2 SET q2 = replace(q2, ' ','');
        update plsport_playsport._question_answer_2 SET q2 = replace(q2, '\\','');
        update plsport_playsport._question_answer_2 SET q2 = replace(q2, '\n','');
        update plsport_playsport._question_answer_2 SET q2 = replace(q2, '\r','');
        update plsport_playsport._question_answer_2 SET q2 = replace(q2, '\t','');
        update plsport_playsport._question_answer_2 SET q4 = replace(q4, ' ','');
        update plsport_playsport._question_answer_2 SET q4 = replace(q4, '\\','');
        update plsport_playsport._question_answer_2 SET q4 = replace(q4, '\n','');
        update plsport_playsport._question_answer_2 SET q4 = replace(q4, '\r','');
        update plsport_playsport._question_answer_2 SET q4 = replace(q4, '\t','');

# 整理後的問券
    SELECT 'userid', 't', 'mins', 'q1', 'a1', 'a2', 'a3', 'a4', 'a5', 'q2', 'q3', 'b1', 'b2', 'b3', 'q4', 'nba', 'mlb' UNION (
    SELECT * 
    INTO outfile 'C:/Users/1-7_ASUS/Desktop/_question_answer_2.csv' 
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
CREATE TABLE actionlog._action_forum engine = myisam
SELECT userid, uri, time, platform_type
FROM actionlog.action_201409
WHERE substr(uri,1,6) = '/forum'
AND userid <> '';

INSERT IGNORE INTO actionlog._action_forum 
SELECT userid, uri, time, platform_type
FROM actionlog.action_20141015
WHERE substr(uri,1,6) = '/forum'
AND userid <> '';

CREATE TABLE actionlog._action_forum_1 engine = myisam
SELECT userid, uri, time, platform_type as pf, 
       (case when (locate('allianceid',uri)=0) then '' else substr(uri,locate('allianceid',uri)+11,length(uri)) end) as alli
FROM actionlog._action_forum;

CREATE TABLE actionlog._action_forum_2 engine = myisam
SELECT userid, uri, time, pf, (case when (locate('&',alli)=0) then '' else substr(alli,1,locate('&',alli)-1) end) as alli
FROM actionlog._action_forum_1;

CREATE TABLE actionlog._action_forum_3 engine = myisam
SELECT userid, uri, time, pf, alli, 
       (case when (locate('subjectid=',uri)=0) then '' else substr(uri,locate('subjectid=',uri)+10,length(uri)) end) as subid
FROM actionlog._action_forum_2;

CREATE TABLE actionlog._action_forum_4 engine = myisam
SELECT userid, uri, time, pf, alli, (case when (locate('&',subid)=0) then '' else substr(subid,1,locate('&',subid)-1) end) as subid
FROM actionlog._action_forum_3;

CREATE TABLE plsport_playsport._forum_allianceid
SELECT subjectid, allianceid, postuser, posttime 
FROM plsport_playsport.forum
WHERE year(posttime) = 2014
ORDER BY posttime DESC;

        #要手動把subid格式換成char(30)
        ALTER TABLE actionlog._action_forum_4 ADD INDEX (`subid`);
        ALTER TABLE plsport_playsport._forum_allianceid ADD INDEX (`subjectid`);
        ALTER TABLE actionlog._action_forum_4 CHANGE `subid` `subid` VARCHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE plsport_playsport._forum_allianceid CHANGE `subjectid` `subjectid` VARCHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

CREATE TABLE actionlog._action_forum_5 engine = myisam
SELECT a.userid, a.uri, a.time, a.pf, a.alli, a.subid, b.allianceid
FROM actionlog._action_forum_4 a LEFT JOIN plsport_playsport._forum_allianceid b on a.subid = b.subjectid;

CREATE TABLE actionlog._action_forum_6 engine = myisam
SELECT userid, uri, time, pf, alli, subid, (case when (allianceid is null) then '' else allianceid end) as allianceid
FROM actionlog._action_forum_5;

CREATE TABLE actionlog._action_forum_7 engine = myisam
SELECT userid, uri, time, pf, alli, subid, allianceid, concat(alli,allianceid) as alli1 
FROM actionlog._action_forum_6;

CREATE TABLE actionlog._action_forum_8 engine = myisam
SELECT userid, uri, date(time) as d, pf, alli, subid, allianceid, alli1 
FROM actionlog._action_forum_7
WHERE alli1 not in ('',0);

CREATE TABLE actionlog._action_forum_8_week1 engine = myisam
SELECT * FROM actionlog._action_forum_8 WHERE d between '2014-09-07' AND '2014-09-13';
CREATE TABLE actionlog._action_forum_8_week2 engine = myisam
SELECT * FROM actionlog._action_forum_8 WHERE d between '2014-09-14' AND '2014-09-20';
CREATE TABLE actionlog._action_forum_8_week3 engine = myisam
SELECT * FROM actionlog._action_forum_8 WHERE d between '2014-09-21' AND '2014-09-27';
CREATE TABLE actionlog._action_forum_8_week4 engine = myisam
SELECT * FROM actionlog._action_forum_8 WHERE d between '2014-09-28' AND '2014-10-04';
CREATE TABLE actionlog._action_forum_8_week5 engine = myisam
SELECT * FROM actionlog._action_forum_8 WHERE d between '2014-10-05' AND '2014-10-11';

# (1) 討論區總觀看使用者數
SELECT count(a.userid) 
FROM (
    SELECT userid FROM actionlog._action_forum_8_week5 # 改week?
    GROUP BY userid) as a;

# (2) 特定看版觀看使用者數
SELECT count(a.userid) 
FROM (
    SELECT userid FROM actionlog._action_forum_8_week5 # 改week?
    WHERE alli1=91 # 改聯盟
    GROUP BY userid) as a;


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

CREATE TABLE plsport_playsport._medal_fire engine = myisam
SELECT * FROM plsport_playsport.medal_fire
WHERE allianceid in (1,2,6,9) # MLB、日棒、中職、韓棒
AND vol > 81;

CREATE TABLE plsport_playsport._single_killer engine = myisam
SELECT * FROM plsport_playsport.single_killer
WHERE allianceid in (1,2,6,9) # MLB、日棒、中職、韓棒
AND vol > 27;

# <^^^^^^^^^^^^^^^^^^^^^^
# 不小心都刪掉了......QQ
# <vvvvvvvvvvvvvvvvvvvvvv

CREATE TABLE plsport_playsport._prediction_201405 engine = myisam
SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth, CREATEday 
FROM prediction.p_201405
WHERE allianceid in (1,2);

CREATE TABLE plsport_playsport._prediction_201405_month engine = myisam
SELECT userid, allianceid, mode, CREATEmonth
FROM plsport_playsport._prediction_201405
GROUP BY userid, allianceid, mode, CREATEmonth;

SELECT allianceid, mode, CREATEmonth, count(userid) as user_count 
FROM plsport_playsport._prediction_201405_month
GROUP BY allianceid, mode, CREATEmonth;

CREATE TABLE plsport_playsport._prediction_201405_day engine = myisam
SELECT userid, allianceid, mode, CREATEday 
FROM plsport_playsport._prediction_201405
GROUP BY userid, allianceid, mode, CREATEday;

CREATE TABLE plsport_playsport._prediction_201405_day1 engine = myisam
SELECT userid, allianceid, mode, count(userid) as day_count 
FROM plsport_playsport._prediction_201405_day
GROUP BY userid, allianceid, mode;

SELECT allianceid, mode, count(userid) as user_count 
FROM plsport_playsport._prediction_201405_day1
WHERE day_count>19
GROUP BY allianceid, mode;


# 4
CREATE TABLE plsport_playsport._prediction_mlb engine = myisam
SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth as m, CREATEday as d 
FROM prediction.p_201402 WHERE allianceid = 1;

INSERT IGNORE INTO plsport_playsport._prediction_mlb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth as m, CREATEday as d 
FROM prediction.p_201403 WHERE allianceid = 1;
INSERT IGNORE INTO plsport_playsport._prediction_mlb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth as m, CREATEday as d 
FROM prediction.p_201404 WHERE allianceid = 1;
INSERT IGNORE INTO plsport_playsport._prediction_mlb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth as m, CREATEday as d 
FROM prediction.p_201405 WHERE allianceid = 1;
INSERT IGNORE INTO plsport_playsport._prediction_mlb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth as m, CREATEday as d 
FROM prediction.p_201406 WHERE allianceid = 1;
INSERT IGNORE INTO plsport_playsport._prediction_mlb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth as m, CREATEday as d 
FROM prediction.p_201407 WHERE allianceid = 1;
INSERT IGNORE INTO plsport_playsport._prediction_mlb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth as m, CREATEday as d 
FROM prediction.p_201408 WHERE allianceid = 1;
INSERT IGNORE INTO plsport_playsport._prediction_mlb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth as m, CREATEday as d 
FROM prediction.p_201409 WHERE allianceid = 1;

CREATE TABLE plsport_playsport._prediction_mlb_1 engine = myisam
SELECT userid, mode, m, min(d) as d 
FROM plsport_playsport._prediction_mlb
GROUP BY userid, mode, m;

SELECT mode, m, count(userid)  
FROM plsport_playsport._prediction_mlb_1
GROUP BY mode, m;

ALTER TABLE `_prediction_mlb_1` CHANGE `userid` `userid` CHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

CREATE TABLE plsport_playsport._prediction_mlb_2 engine = myisam
SELECT a.userid, a.mode, a.m, a.d, date(b.CREATEon) as join_d
FROM plsport_playsport._prediction_mlb_1 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

ALTER TABLE `_prediction_mlb_2` CHANGE `d` `d` DATE NULL DEFAULT NULL;

CREATE TABLE plsport_playsport._prediction_mlb_3 engine = myisam
SELECT userid, mode, m, d, join_d, round((datediff(d,join_d)/30),0) as dif
FROM plsport_playsport._prediction_mlb_2;


CREATE TABLE plsport_playsport._prediction_mlb_4 engine = myisam
SELECT userid, mode, m, (case when (dif<7) then '6'
                              when (dif<13) then '12'
                              when (dif<19) then '18'
                              when (dif<23) then '24'
                              when (dif<29) then '30'
                              when (dif<35) then '36' 
                              else '37' end) as dif
FROM plsport_playsport._prediction_mlb_3;

# 4-日棒
CREATE TABLE plsport_playsport._prediction_jpb engine = myisam
SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth as m, CREATEday as d 
FROM prediction.p_201402 WHERE allianceid = 2;

INSERT IGNORE INTO plsport_playsport._prediction_jpb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth as m, CREATEday as d 
FROM prediction.p_201403 WHERE allianceid = 2;
INSERT IGNORE INTO plsport_playsport._prediction_jpb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth as m, CREATEday as d 
FROM prediction.p_201404 WHERE allianceid = 2;
INSERT IGNORE INTO plsport_playsport._prediction_jpb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth as m, CREATEday as d 
FROM prediction.p_201405 WHERE allianceid = 2;
INSERT IGNORE INTO plsport_playsport._prediction_jpb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth as m, CREATEday as d 
FROM prediction.p_201406 WHERE allianceid = 2;
INSERT IGNORE INTO plsport_playsport._prediction_jpb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth as m, CREATEday as d 
FROM prediction.p_201407 WHERE allianceid = 2;
INSERT IGNORE INTO plsport_playsport._prediction_jpb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth as m, CREATEday as d 
FROM prediction.p_201408 WHERE allianceid = 2;
INSERT IGNORE INTO plsport_playsport._prediction_jpb SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth as m, CREATEday as d 
FROM prediction.p_201409 WHERE allianceid = 2;

CREATE TABLE plsport_playsport._prediction_jpb_1 engine = myisam
SELECT userid, mode, m, min(d) as d 
FROM plsport_playsport._prediction_jpb
GROUP BY userid, mode, m;

SELECT mode, m, count(userid)  
FROM plsport_playsport._prediction_jpb_1
GROUP BY mode, m;

ALTER TABLE `_prediction_jpb_1` CHANGE `userid` `userid` CHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

CREATE TABLE plsport_playsport._prediction_jpb_2 engine = myisam
SELECT a.userid, a.mode, a.m, a.d, date(b.CREATEon) as join_d
FROM plsport_playsport._prediction_jpb_1 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

ALTER TABLE `_prediction_jpb_2` CHANGE `d` `d` DATE NULL DEFAULT NULL;

CREATE TABLE plsport_playsport._prediction_jpb_3 engine = myisam
SELECT userid, mode, m, d, join_d, round((datediff(d,join_d)/30),0) as dif
FROM plsport_playsport._prediction_jpb_2;


CREATE TABLE plsport_playsport._prediction_jpb_4 engine = myisam
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
GROUP BY m, mode, dif;


# 4-所有聯盟
CREATE TABLE plsport_playsport._prediction_all engine = myisam
SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth as m, CREATEday as d 
FROM prediction.p_201402;

INSERT IGNORE INTO plsport_playsport._prediction_all SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth as m, CREATEday as d 
FROM prediction.p_201403;
INSERT IGNORE INTO plsport_playsport._prediction_all SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth as m, CREATEday as d 
FROM prediction.p_201404;
INSERT IGNORE INTO plsport_playsport._prediction_all SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth as m, CREATEday as d 
FROM prediction.p_201405;
INSERT IGNORE INTO plsport_playsport._prediction_all SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth as m, CREATEday as d 
FROM prediction.p_201406;
INSERT IGNORE INTO plsport_playsport._prediction_all SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth as m, CREATEday as d 
FROM prediction.p_201407;
INSERT IGNORE INTO plsport_playsport._prediction_all SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth as m, CREATEday as d 
FROM prediction.p_201408;
INSERT IGNORE INTO plsport_playsport._prediction_all SELECT userid, allianceid, (case when (gametype<4) then 'TWN' else 'INT' end) as mode, CREATEon, CREATEmonth as m, CREATEday as d 
FROM prediction.p_201409;

CREATE TABLE plsport_playsport._prediction_all_1 engine = myisam
SELECT userid, mode, m, min(d) as d 
FROM plsport_playsport._prediction_all
GROUP BY userid, mode, m;

SELECT mode, m, count(userid)  
FROM plsport_playsport._prediction_jpb_1
GROUP BY mode, m;

ALTER TABLE `_prediction_all_1` CHANGE `userid` `userid` CHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

CREATE TABLE plsport_playsport._prediction_all_2 engine = myisam
SELECT a.userid, a.mode, a.m, a.d, date(b.CREATEon) as join_d
FROM plsport_playsport._prediction_all_1 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

ALTER TABLE `_prediction_all_2` CHANGE `d` `d` DATE NULL DEFAULT NULL;

CREATE TABLE plsport_playsport._prediction_all_3 engine = myisam
SELECT userid, mode, m, d, join_d, round((datediff(d,join_d)/30),0) as dif
FROM plsport_playsport._prediction_all_2;


CREATE TABLE plsport_playsport._prediction_all_4 engine = myisam
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
GROUP BY m, mode, dif;


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

CREATE TABLE plsport_playsport._order_data_2014 engine = myisam
SELECT userid, CREATEon, ordernumber, price, payway  
FROM plsport_playsport.order_data
WHERE sellconfirm = 1
AND payway in (1,2,3,4,5,6,9,10)
AND year(CREATEon) = 2014
ORDER BY id DESC;

CREATE TABLE plsport_playsport._order_data_2014_1 engine = myisam
SELECT userid, CREATEon, ordernumber, payway, price, 
       (case when (price < 229) then 199
             when (price < 804) then 699
             when (price < 1149) then 999 else price end) as raw_price
FROM plsport_playsport._order_data_2014;

CREATE TABLE plsport_playsport._user_total_paid_in_2014 engine = myisam
SELECT userid, sum(price) as total_paid 
FROM plsport_playsport._order_data_2014_1
GROUP BY userid;

        ALTER TABLE plsport_playsport._user_total_paid_in_2014 ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._order_data_2014_1 ADD INDEX (`userid`);

CREATE TABLE plsport_playsport._order_data_2014_2 engine = myisam
SELECT a.userid, a.CREATEon, a.ordernumber, a.payway, a.price, a.raw_price, b.total_paid  
FROM plsport_playsport._order_data_2014_1 a LEFT JOIN plsport_playsport._user_total_paid_in_2014 b on a.userid = b.userid;

CREATE TABLE plsport_playsport._order_data_2014_3 engine = myisam
SELECT userid, CREATEon, ordernumber, payway, price, raw_price, total_paid, 
       (case when (total_paid > 99999) then 'svip'
             when (total_paid > 49999 AND total_paid < 100000) then 'vvip'
             when (total_paid > 19999 AND total_paid < 50000) then 'vip' else 'none' end) as lv
FROM plsport_playsport._order_data_2014_2;

CREATE TABLE plsport_playsport._order_data_2014_4 engine = myisam
SELECT * FROM plsport_playsport._order_data_2014_3
WHERE lv <> 'none';

CREATE TABLE plsport_playsport._order_data_2014_5 engine = myisam
SELECT a.userid, sum(a.p_199) as p_199, sum(a.p_699) as p_699, sum(a.p_999) as p_999, sum(a.p_1999) as p_1999,
                 sum(a.p_3999) as p_3999, sum(a.p_8888) as p_8888, sum(a.p_16888) as p_16888, a.lv
FROM (
    SELECT userid, CREATEon, 
           (case when (raw_price = 199) then 1 else 0 end) as p_199,
           (case when (raw_price = 699) then 1 else 0 end) as p_699,
           (case when (raw_price = 999) then 1 else 0 end) as p_999,
           (case when (raw_price = 1999) then 1 else 0 end) as p_1999,
           (case when (raw_price = 3999) then 1 else 0 end) as p_3999,
           (case when (raw_price = 8888) then 1 else 0 end) as p_8888,
           (case when (raw_price = 16888) then 1 else 0 end) as p_16888, lv 
    FROM plsport_playsport._order_data_2014_4) as a
GROUP BY a.userid;

CREATE TABLE plsport_playsport._order_data_2014_6 engine = myisam
SELECT a.userid, a.p_199, a.p_699, a.p_999, a.p_1999, a.p_3999, a.p_8888, a.p_16888, a.lv, b.total_paid 
FROM plsport_playsport._order_data_2014_5 a LEFT JOIN plsport_playsport._user_total_paid_in_2014 b on a.userid = b.userid;

    # 輸出
    SELECT 'userid', 'p_199', 'p_699', 'p_999', 'p_1999', 'p_3999', 'p_8888', 'p_16888', 'lv', 'total_paid' UNION (
    SELECT * 
    INTO outfile 'C:/Users/1-7_ASUS/Desktop/_order_data_2014_6.csv' 
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
# 2.  全站佔比指的是跟全站使用者相比
# =================================================================================================

# update: 2014-11-24 同樣的篩選條件下, 阿達需要依資料區間：11/5 ~ 11/20重跑一次名單
#         今天action_log更新至11-23, 所以 資料區間：11/5 ~ 11/23

CREATE TABLE actionlog._actionlog_livescore engine = myisam 
SELECT userid, uri, time, platform_type 
FROM actionlog.action_20141123
WHERE date(time) between '2014-11-05' AND '2014-11-23'
AND uri LIKE '%/livescore.php%'
AND userid <> '';

# actionlog._actionlog_livescore_1~3捉出聯盟

CREATE TABLE actionlog._actionlog_livescore_1 engine = myisam
SELECT a.userid, a.uri, (case when (locate('&',a.p)=0) then a.p
                              else substr(a.p,1,locate('&',a.p)-1) end) as p, a.time, a.platform_type
FROM (
    SELECT userid, uri, substr(uri,locate('aid',uri)+4,length(uri)) as p, time, platform_type 
    FROM actionlog._actionlog_livescore) as a;

CREATE TABLE actionlog._actionlog_livescore_2 engine = myisam
SELECT userid, uri, (case when (p in ('1#','vescore.php')) then 1 else p end) as p, time, 
                    (case when (platform_type < 2) then 'desktop' else 'mobile' end) as platform 
FROM actionlog._actionlog_livescore_1;

CREATE TABLE actionlog._actionlog_livescore_3 engine = myisam
SELECT a.userid, a.uri, b.alliancename, a.time, a.platform 
FROM actionlog._actionlog_livescore_2 a LEFT JOIN plsport_playsport.alliance b on a.p = b.allianceid;

# (1)看即時比分的天數
CREATE TABLE actionlog._actionlog_livescore_3_usage_daycount_all engine = myisam
SELECT b.userid, count(b.d) as d_count_all
FROM (
    SELECT a.userid, a.d, count(userid) as c
    FROM (
        SELECT userid, uri, alliancename as alli_name, date(time) as d, platform 
        FROM actionlog._actionlog_livescore_3) as a
    GROUP BY a.userid, a.d) as b
GROUP BY b.userid;

# (2)看即時比分的天數-NBA
CREATE TABLE actionlog._actionlog_livescore_3_usage_daycount_nba engine = myisam
SELECT b.userid, count(b.d) as d_count_nba
FROM (
    SELECT a.userid, a.d, count(a.userid ) as c
    FROM (
        SELECT userid, alliancename, date(time) as d 
        FROM actionlog._actionlog_livescore_3
        WHERE alliancename = 'NBA') as a
    GROUP BY a.userid, a.d) as b
GROUP BY b.userid;

# (3)看即時比分的天數-NHL冰球
CREATE TABLE actionlog._actionlog_livescore_3_usage_daycount_nhl engine = myisam
SELECT b.userid, count(b.d) as d_count_nhl
FROM (
    SELECT a.userid, a.d, count(a.userid) as c
    FROM (
        SELECT userid, alliancename, date(time) as d 
        FROM actionlog._actionlog_livescore_3
        WHERE alliancename = '冰球') as a
    GROUP BY a.userid, a.d) as b
GROUP BY b.userid;

# (4)使用裝置的比例
CREATE TABLE actionlog._actionlog_livescore_3_pv_precentage engine = myisam
SELECT c.userid, c.desktop_pv, c.mobile_pv, round((c.desktop_pv/(c.desktop_pv+c.mobile_pv)),3) as desktop_p,
                                            round((c.mobile_pv/(c.desktop_pv+c.mobile_pv)),3) as mobile_p
FROM (
    SELECT b.userid, sum(b.desktop_pv) as desktop_pv, sum(b.mobile_pv) as mobile_pv
    FROM (
        SELECT a.userid, (case when (a.platform='desktop') then c else 0 end) as desktop_pv,
                         (case when (a.platform='mobile')  then c else 0 end) as mobile_pv
        FROM (
            SELECT userid, platform, count(userid) as c 
            FROM actionlog._actionlog_livescore_3
            GROUP BY userid, platform) as a) as b
    GROUP BY b.userid) as c;

CREATE TABLE actionlog._actionlog_livescore_3_nba_pv engine = myisam
SELECT userid, count(userid) as nba_pv
FROM actionlog._actionlog_livescore_3
WHERE alliancename = 'NBA'
GROUP BY userid;

        ALTER TABLE actionlog._actionlog_livescore_3_nba_pv CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

CREATE TABLE actionlog._actionlog_livescore_3_nhl_pv engine = myisam
SELECT userid, count(userid) as nhl_pv
FROM actionlog._actionlog_livescore_3
WHERE alliancename = '冰球'
GROUP BY userid;

        ALTER TABLE actionlog._actionlog_livescore_3_nhl_pv CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

use plsport_playsport;

# (1)
CREATE TABLE plsport_playsport._list_1 engine = myisam
SELECT c.userid, c.d_count_all, c.d_count_nba, d.d_count_nhl
FROM (
    SELECT a.userid, a.d_count_all, b.d_count_nba
    FROM actionlog._actionlog_livescore_3_usage_daycount_all a LEFT JOIN actionlog._actionlog_livescore_3_usage_daycount_nba b on a.userid = b.userid) as c
    LEFT JOIN actionlog._actionlog_livescore_3_usage_daycount_nhl as d on c.userid = d.userid;

        ALTER TABLE `_list_1` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

# (2)
CREATE TABLE plsport_playsport._list_2 engine = myisam
SELECT a.userid, b.nickname, a.d_count_all, a.d_count_nba, a.d_count_nhl 
FROM plsport_playsport._list_1 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

        ALTER TABLE actionlog._actionlog_livescore_3_pv_precentage CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

CREATE TABLE plsport_playsport._list_3 engine = myisam
SELECT a.userid, a.nickname, a.d_count_all, a.d_count_nba, a.d_count_nhl, b.desktop_pv, b.mobile_pv, b.desktop_p, b.mobile_p
FROM plsport_playsport._list_2 a LEFT JOIN actionlog._actionlog_livescore_3_pv_precentage b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_4 engine = myisam
SELECT a.userid, a.nickname, a.d_count_all, a.d_count_nba, a.d_count_nhl, b.nba_pv, a.desktop_pv, a.mobile_pv, a.desktop_p, a.mobile_p 
FROM plsport_playsport._list_3 a LEFT JOIN actionlog._actionlog_livescore_3_nba_pv b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_5 engine = myisam
SELECT a.userid, a.nickname, a.d_count_all, a.d_count_nba, a.d_count_nhl, a.nba_pv, b.nhl_pv, a.desktop_pv, a.mobile_pv, a.desktop_p, a.mobile_p
FROM plsport_playsport._list_4 a LEFT JOIN actionlog._actionlog_livescore_3_nhl_pv b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_6 engine = myisam
SELECT * FROM plsport_playsport._list_5
WHERE nba_pv is not null;

        # ...最後一次登入的時間
        CREATE TABLE plsport_playsport._last_signin engine = myisam # 最近一次登入
        SELECT userid, max(signin_time) as last_signin
        FROM plsport_playsport.member_signin_log_archive
        GROUP BY userid;

        ALTER TABLE plsport_playsport._list_6 CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE plsport_playsport._last_signin CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE plsport_playsport._list_6 ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._last_signin ADD INDEX (`userid`);

CREATE TABLE plsport_playsport._list_7 engine = myisam
SELECT a.userid, a.nickname, date(b.last_signin) as last_signin, a.d_count_all, a.d_count_nba, a.d_count_nhl, a.nba_pv, a.nhl_pv, a.desktop_pv, a.mobile_pv, a.desktop_p, a.mobile_p
FROM plsport_playsport._list_6 a LEFT JOIN plsport_playsport._last_signin b on a.userid = b.userid;

# 最後名單
    SELECT 'userid', 'nickname', 'last_signin', 'd_count_all', 'd_count_nba', 'd_count_nhl', 'nba_pv', 'nhl_pv', 'desktop_pv', 'mobile_pv', 'desktop_p', 'mobile_p' UNION (
    SELECT * 
    INTO outfile 'C:/Users/1-7_ASUS/Desktop/_list_7.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._list_7);


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

# 2014-12-22 重跑一次名單
# 先撈出戰績勝率頁的action_log
CREATE TABLE actionlog._visit_member_records_all engine = myisam 
SELECT userid, uri, time, platform_type FROM actionlog.action_201409 WHERE uri LIKE '%visit_member.php?action=records&type=all%' AND userid <> '';

INSERT IGNORE INTO actionlog._visit_member_records_all SELECT userid, uri, time, platform_type 
FROM actionlog.action_201410 WHERE uri LIKE '%visit_member.php?action=records&type=all%' AND userid <> '';
INSERT IGNORE INTO actionlog._visit_member_records_all SELECT userid, uri, time, platform_type 
FROM actionlog.action_201411 WHERE uri LIKE '%visit_member.php?action=records&type=all%' AND userid <> '';
INSERT IGNORE INTO actionlog._visit_member_records_all SELECT userid, uri, time, platform_type 
FROM actionlog.action_20141220 WHERE uri LIKE '%visit_member.php?action=records&type=all%' AND userid <> '';

CREATE TABLE actionlog._visit_member_records_all_in_three_month engine = myisam 
SELECT *
FROM actionlog._visit_member_records_all
WHERE time between subdate(now(),90) AND now(); # 近三個月

CREATE TABLE actionlog._visit_member_records_all_everyone_pv engine = myisam 
SELECT userid, count(userid) as record_pv 
FROM actionlog._visit_member_records_all_in_three_month
GROUP BY userid;

# 當莊殺次數
CREATE TABLE plsport_playsport._medal_fire_count engine = myisam
SELECT a.userid, a.nickname, count(userid) as medal_fire_count
FROM (
    SELECT id, vol, userid, nickname, allianceid, alliancename, winpercentage, winearn 
    FROM plsport_playsport.medal_fire
    WHERE vol > 107) as a # 莊殺108期(含)是2014年的期數
GROUP BY a.userid;

# 當單殺次數
CREATE TABLE plsport_playsport._single_killer_count engine = myisam
SELECT a.userid, a.nickname, count(userid) as single_killer_count
FROM (
    SELECT * 
    FROM plsport_playsport.single_killer
    WHERE vol > 39) as a # 單殺40期(含)之後是2014年的期數
GROUP BY a.userid;

# 近3個月的儲值
CREATE TABLE plsport_playsport._redeem_in_three_month engine = myisam
SELECT a.userid, sum(a.price) as redeem_in_three_month
FROM (
    SELECT userid, CREATEon, ordernumber, price, payway
    FROM plsport_playsport.order_data
    WHERE sellconfirm = 1
    AND payway in (1,2,3,4,5,6,9,10)
    AND CREATEon between subdate(now(),90) AND now()) as a # 近三個月
GROUP BY a.userid;

# 最近一次登入
CREATE TABLE plsport_playsport._last_signin engine = myisam # 最近一次登入
SELECT userid, max(signin_time) as last_signin
FROM plsport_playsport.member_signin_log_archive
GROUP BY userid;


ALTER TABLE actionlog._visit_member_records_all_everyone_pv convert to character SET utf8 collate utf8_general_ci;
ALTER TABLE plsport_playsport._last_signin convert to character SET utf8 collate utf8_general_ci;

# 1
CREATE TABLE plsport_playsport._list_1 engine = myisam
SELECT a.userid, b.nickname, a.record_pv 
FROM actionlog._visit_member_records_all_everyone_pv a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;
# 2
CREATE TABLE plsport_playsport._list_2 engine = myisam
SELECT c.userid, c.nickname, c.record_pv, c.medal_fire_count, d.single_killer_count
FROM (
    SELECT a.userid, a.nickname, a.record_pv, b.medal_fire_count
    FROM plsport_playsport._list_1 a LEFT JOIN plsport_playsport._medal_fire_count b on a.userid = b.userid) as c 
    LEFT JOIN plsport_playsport._single_killer_count as d on c.userid = d.userid;
# 3
CREATE TABLE plsport_playsport._list_3 engine = myisam
SELECT a.userid, a.nickname, a.record_pv, a.medal_fire_count, a.single_killer_count, b.redeem_in_three_month  
FROM plsport_playsport._list_2 a LEFT JOIN plsport_playsport._redeem_in_three_month b on a.userid = b.userid;
# 4
CREATE TABLE plsport_playsport._list_4 engine = myisam
SELECT a.userid, a.nickname, a.record_pv, a.medal_fire_count, a.single_killer_count, a.redeem_in_three_month, date(b.last_signin) as last_signin
FROM plsport_playsport._list_3 a LEFT JOIN plsport_playsport._last_signin b on a.userid = b.userid;

# 輸出txt
SELECT 'userid', 'nickname', 'record_pv', 'mdeal_fire', 'single_killer', 'redeem', 'last_signin' UNION (
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_list_4.txt'
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
# <--以下是abtesting檢查的部分-->
CREATE TABLE plsport_playsport._forumcontent engine = myisam
SELECT * FROM plsport_playsport.forumcontent
WHERE articleid > 11200000;

        ALTER TABLE plsport_playsport._forumcontent ADD INDEX (`articleid`);
        ALTER TABLE plsport_playsport.abtesting_forum_reply_enhanced ADD INDEX (`articleid`);

CREATE TABLE plsport_playsport._forumcontent_with_post_method engine = myisam
SELECT a.articleid, a.subjectid, a.userid, a.contenttype, a.postdate, b.post_FROM
FROM plsport_playsport._forumcontent a LEFT JOIN plsport_playsport.abtesting_forum_reply_enhanced b on a.articleid = b.articleid
WHERE post_FROM is not null
ORDER BY a.articleid;

CREATE TABLE plsport_playsport._forumcontent_with_post_method_1 engine = myisam
SELECT (case when (c.g>10) then 'a' else 'b' end) as abtest, c.g, c.articleid, c.subjectid, c.userid, c.contenttype, c.postdate, c.post_FROM
FROM (
    SELECT (b.id%20)+1 as g, a.articleid, a.subjectid, a.userid, a.contenttype, a.postdate, a.post_FROM
    FROM plsport_playsport._forumcontent_with_post_method a LEFT JOIN plsport_playsport.member b on a.userid = b.userid) as c;

# 檢查
SELECT abtest, post_FROM, count(userid) as c 
FROM plsport_playsport._forumcontent_with_post_method_1
GROUP BY abtest, post_FROM;

# <--以下才是abtesting檢驗的部分--> 開始做abtesting 2014-11-14
#     WHERE date(postdate) between '2014-10-30' AND '2014-11-13'
# 第二次abtesting
#     WHERE date(postdate) between '2014-11-14' AND '2014-11-25'
# PS.linode滿了, 所以26~27沒有actionlog
CREATE TABLE plsport_playsport._forumcontent engine = myisam
SELECT * FROM plsport_playsport.forumcontent
WHERE date(postdate) between '2014-11-14' AND '2014-11-25';

        ALTER TABLE plsport_playsport._forumcontent ADD INDEX (`articleid`);
        ALTER TABLE plsport_playsport.abtesting_forum_reply_enhanced ADD INDEX (`articleid`);

CREATE TABLE plsport_playsport._forumcontent_with_post_method engine = myisam
SELECT a.articleid, a.subjectid, a.userid, a.contenttype, a.postdate, b.post_FROM
FROM plsport_playsport._forumcontent a LEFT JOIN plsport_playsport.abtesting_forum_reply_enhanced b on a.articleid = b.articleid
WHERE post_FROM is not null
ORDER BY a.articleid;

CREATE TABLE plsport_playsport._forumcontent_with_post_method_1 engine = myisam
SELECT (case when (c.g>10) then 'a' else 'b' end) as abtest, c.g, c.articleid, c.subjectid, c.userid, c.contenttype, c.postdate, c.post_FROM
FROM (
    SELECT (b.id%20)+1 as g, a.articleid, a.subjectid, a.userid, a.contenttype, a.postdate, a.post_FROM
    FROM plsport_playsport._forumcontent_with_post_method a LEFT JOIN plsport_playsport.member b on a.userid = b.userid) as c;

CREATE TABLE plsport_playsport._forumcontent_with_post_method_2 engine = myisam
SELECT abtest, g, articleid, subjectid, userid, postdate, post_FROM, concat(abtest,'_',post_FROM) as u
FROM plsport_playsport._forumcontent_with_post_method_1;

CREATE TABLE plsport_playsport._forumcontent_with_post_method_3 engine = myisam
SELECT *
FROM plsport_playsport._forumcontent_with_post_method_2
WHERE u not in ('a_1','b_2');

# 2組使用者人數比較 (來做chi-square檢驗)
        # 所有人
        SELECT a.abtest, count(a.userid) as user_count
        FROM (
            SELECT abtest, g, userid, count(articleid) as reply_count 
            FROM plsport_playsport._forumcontent_with_post_method_3
            GROUP BY abtest, g, userid) as a
        GROUP BY a.abtest;
        # 有在用的人
        SELECT a.abtest, count(a.userid) as c
        FROM (
            SELECT abtest, userid, count(articleid) as c 
            FROM plsport_playsport._forumcontent_with_post_method_3
            WHERE u in ('a_2','b_1')
            GROUP BY abtest, userid) as a
        GROUP BY a.abtest;

        # 是否有人會2種版本都用?
        SELECT a.abtest, a.g, a.userid, sum(ver0) as ver0,sum(ver1) as ver1,sum(ver2) as ver2
        FROM (
            SELECT abtest, g, userid, (case when (post_FROM=0) then 1 else 0 end) as ver0, 
                                      (case when (post_FROM=1) then 1 else 0 end) as ver1, 
                                      (case when (post_FROM=2) then 1 else 0 end) as ver2
            FROM plsport_playsport._forumcontent_with_post_method_3) as a
        GROUP BY a.abtest, a.g, a.userid;


# 每位使用者的回文數(準備要輸出給R用)
CREATE TABLE plsport_playsport._user_reply_count engine = myisam
SELECT abtest, g, userid, count(articleid) as reply_count 
FROM plsport_playsport._forumcontent_with_post_method_3
GROUP BY abtest, g, userid;

    # 輸出.txt給R
    SELECT 'abtest', 'g', 'userid', 'reply_count' UNION (
    SELECT *
    INTO outfile 'C:/Users/1-7_ASUS/Desktop/_user_reply_count.txt'
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
    FROM plsport_playsport._user_reply_count);


# update 2014-11-17 
# 排除掉回文太多的人>300
CREATE TABLE plsport_playsport._forumcontent_with_post_method_4_only_normal_reply_people engine = myisam
SELECT e.abtest, e.g, e.articleid, e.subjectid, e.userid, e.postdate, e.post_FROM, e.u 
FROM plsport_playsport._forumcontent_with_post_method_3 as e inner join (SELECT a.userid
                                                                         FROM (
                                                                             SELECT userid, count(articleid) as reply_count 
                                                                             FROM plsport_playsport._forumcontent_with_post_method_3
                                                                             GROUP BY userid) as a
                                                                         WHERE a.reply_count <= 300
                                                                         ORDER BY a.reply_count DESC) as f on e.userid = f.userid;
# 沒有排除
SELECT u, count(articleid) as c 
FROM plsport_playsport._forumcontent_with_post_method_3
GROUP BY u;

# 有排除
SELECT u, count(articleid) as c 
FROM plsport_playsport._forumcontent_with_post_method_4_only_normal_reply_people
GROUP BY u;

# 只看手機回文的人(手機界面回文新版和舊版)
CREATE TABLE plsport_playsport._forumcontent_with_post_method_5_only_use_mobile_reply_people engine = myisam
SELECT abtest, userid, count(articleid) as reply_count 
FROM plsport_playsport._forumcontent_with_post_method_4_only_normal_reply_people
WHERE substr(u,3,1) <> '0'
GROUP BY abtest, userid;

    SELECT abtest, count(userid) as c 
    FROM plsport_playsport._forumcontent_with_post_method_5_only_use_mobile_reply_people
    GROUP BY abtest;

    # 輸出.txt給R
    SELECT 'abtest',  'userid', 'reply_count' UNION (
    SELECT *
    INTO outfile 'C:/Users/1-7_ASUS/Desktop/_forumcontent_with_post_method_5_only_use_mobile_reply_people.txt'
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
    FROM plsport_playsport._forumcontent_with_post_method_5_only_use_mobile_reply_people);

# update 2014-11-20
# 要製作名單給靜怡
# 有回答問券的人, 然後在後面補上他們的回文方式和回文數

CREATE TABLE plsport_playsport._user_reply_count_detail engine = myisam
SELECT b.abtest, b.userid, b.post_by_pc, b.post_by_mobile, (b.post_by_pc+b.post_by_mobile) as post_count
FROM (
    SELECT a.abtest, a.userid, sum(a.post_by_pc) as post_by_pc, sum(a.post_by_mobile) as post_by_mobile
    FROM (
        SELECT abtest, g, articleid, subjectid, userid, postdate, 
               (case when (post_FROM=0) then 1 else 0 end) as post_by_pc,
               (case when (post_FROM>0) then 1 else 0 end) as post_by_mobile, post_FROM, u
        FROM plsport_playsport._forumcontent_with_post_method_3) as a
    GROUP BY a.abtest, a.userid) as b;

CREATE TABLE plsport_playsport._last_signin engine = myisam # 最近一次登入
SELECT userid, max(signin_time) as last_signin
FROM plsport_playsport.member_signin_log_archive
GROUP BY userid;

CREATE TABLE plsport_playsport._questionnarie_list_1 engine = myisam
SELECT a.userid, b.nickname, date(b.CREATEon) as join_date, date(a.write_time) as write_date, a.question01, a.question02, a.question03 
FROM plsport_playsport.questionnaire_forumreplyenhancedtemplate_answer a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

CREATE TABLE plsport_playsport._questionnarie_list_2 engine = myisam
SELECT a.userid, a.nickname, a.join_date, a.write_date, a.question01, a.question02, a.question03, b.post_by_pc, b.post_by_mobile, b.post_count
FROM plsport_playsport._questionnarie_list_1 a LEFT JOIN plsport_playsport._user_reply_count_detail b on a.userid = b.userid;

CREATE TABLE plsport_playsport._questionnarie_list_3 engine = myisam
SELECT a.userid, a.nickname, a.join_date, a.write_date, a.question01, a.question02, a.question03, a.post_by_pc, a.post_by_mobile, a.post_count, date(b.last_signin) as last_signin
FROM plsport_playsport._questionnarie_list_2 a LEFT JOIN plsport_playsport._last_signin b on a.userid = b.userid;

ALTER TABLE plsport_playsport._questionnarie_list_3 convert to character SET utf8 collate utf8_general_ci;

update plsport_playsport._questionnarie_list_3 SET question03 = replace(question03, '.',''); 
update plsport_playsport._questionnarie_list_3 SET question03 = replace(question03, ';','');
update plsport_playsport._questionnarie_list_3 SET question03 = replace(question03, '/','');
update plsport_playsport._questionnarie_list_3 SET question03 = replace(question03, '\\','_'); # backslash
update plsport_playsport._questionnarie_list_3 SET question03 = replace(question03, '"','');
update plsport_playsport._questionnarie_list_3 SET question03 = replace(question03, '&','');
update plsport_playsport._questionnarie_list_3 SET question03 = replace(question03, '#','');
update plsport_playsport._questionnarie_list_3 SET question03 = replace(question03, ' ','');
update plsport_playsport._questionnarie_list_3 SET question03 = replace(question03, '\t',''); # replace tab
update plsport_playsport._questionnarie_list_3 SET question03 = replace(question03, '\n',''); # replace new lines
update plsport_playsport._questionnarie_list_3 SET question03 = replace(question03, '\b',''); # replace backspace

    # 輸出.txt
    SELECT 'userid','nickname','join_date','write_date','question01','question02','question03','post_by_pc','post_by_mobile','post_count','last_signin' UNION (
    SELECT *
    INTO outfile 'C:/Users/1-7_ASUS/Desktop/_questionnarie_list_3.txt'
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
    FROM plsport_playsport._questionnarie_list_3);


# =================================================================================================
# 任務: [201406-B-10]強化玩家搜尋-優化電訪名單撈取 [新建] (靜怡) 2014-12-01
# 
# 說明
# 提供電訪名單
# 
# 內容
# - 族群：D1~D5
# - 使用新版玩家搜尋
# - 撈取時段：8/22~11/19
# - 欄位：暱稱、ID、玩家搜尋PV、玩家搜尋使用比例(重度、中度、輕度)、電腦與手機使用比率、最近登入時間
# =================================================================================================

CREATE TABLE actionlog._usersearch_0 engine = myisam
SELECT * FROM actionlog.action_201408 WHERE userid <> '' AND uri LIKE '%usersearch%';
INSERT IGNORE INTO actionlog._usersearch_0 
SELECT * FROM actionlog.action_201409 WHERE userid <> '' AND uri LIKE '%usersearch%';
INSERT IGNORE INTO actionlog._usersearch_0 
SELECT * FROM actionlog.action_201410 WHERE userid <> '' AND uri LIKE '%usersearch%';
INSERT IGNORE INTO actionlog._usersearch_0 
SELECT * FROM actionlog.action_201411 WHERE userid <> '' AND uri LIKE '%usersearch%';

CREATE TABLE actionlog._usersearch_1 engine = myisam
SELECT userid, uri, time, platform_type 
FROM actionlog._usersearch_0
WHERE date(time) between '2014-08-22' AND '2014-11-19';

ALTER TABLE actionlog._usersearch_1 convert to character SET utf8 collate utf8_general_ci;
ALTER TABLE actionlog._usersearch_1 ADD INDEX (`userid`);

CREATE TABLE actionlog._usersearch_2 engine = myisam
SELECT c.g, (case when (c.g<8) then 'a' else 'b' end) as abtest, c.userid, c.nickname, c.uri, c.time, c.platform_type
FROM (
    SELECT (b.id%20)+1 as g, a.userid, b.nickname, a.uri, a.time, a.platform_type 
    FROM actionlog._usersearch_1 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid) as c;

CREATE TABLE actionlog._usersearch_3 engine = myisam
SELECT g, abtest, userid, nickname, uri, time, (case when (platform_type<2) then 1 else 2 end) as platform_type
FROM actionlog._usersearch_2;

CREATE TABLE actionlog._usersearch_4 engine = myisam
SELECT a.g, a.abtest, a.userid, a.nickname, sum(a.pc) as pc, sum(a.mobile) as mobile
FROM (
    SELECT g, abtest, userid, nickname, uri, time, (case when (platform_type=1) then 1 else 0 end) as pc,
                                                  (case when (platform_type=2) then 1 else 0 end) as mobile
    FROM actionlog._usersearch_3) as a
GROUP BY a.g, a.abtest, a.userid;

CREATE TABLE actionlog._usersearch_5 engine = myisam
SELECT g, abtest, userid, nickname, (pc+mobile) as pv, pc, mobile, round((pc/(pc+mobile)),2) as pc_p, round((mobile/(pc+mobile)),2) as mobile_p
FROM actionlog._usersearch_4;


CREATE TABLE plsport_playsport._last_signin engine = myisam # 最近一次登入
SELECT userid, max(signin_time) as last_signin
FROM plsport_playsport.member_signin_log_archive
GROUP BY userid;

        ALTER TABLE actionlog._usersearch_5 ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._last_signin ADD INDEX (`userid`);

CREATE TABLE actionlog._usersearch_6 engine = myisam
SELECT a.g, a.abtest, a.userid, a.nickname, a.pv, a.pc, a.mobile, a.pc_p, a.mobile_p, date(b.last_signin) as last_signin
FROM actionlog._usersearch_5 a LEFT JOIN plsport_playsport._last_signin b on a.userid = b.userid;

CREATE TABLE actionlog._usersearch_7 engine = myisam
SELECT * FROM actionlog._usersearch_6
WHERE abtest = 'a';

SELECT 'g', 'abtest', 'userid', 'nickname', 'pv', 'pc', 'mobile', 'pc_p', 'mobile_p', 'last_signin' UNION (
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_usersearch_7.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._usersearch_7);

# =================================================================================================
# 任務: [201411-C-1] 討論區APP使用者訪談 - 訪談名單 [新建] (阿達) 2014-12-03
# http://pm.playsport.cc/index.php/tasksComments?tasksId=3901&projectId=11
# 說明
#  
# 撈取訪談名單
# 負責人：Eddy 
# 時間：12/3(三) 
# 訪談名單
# 
# 1. 討論區APP使用者
#    a. 分享者
#    條件：
#    - 近三個月討論區app發文數於前 50%或回文數於前 50%
#    - 近三個月登入天數大於 30天
#  
# 欄位：帳號、暱稱、討論區app登入天數/開啟次數、討論區app發文數/回文數、居住地
# 註：以上數字皆統計近三個月即可
#  
#    b. 觀看者
#    條件：
#    - 近三個月討論區app觀看文章數於前50% -> 近三個月討論區app開啟次數高於前50%
#    - 近三個月登入天數大於 30天
# 欄位：帳號、暱稱、討論區app登入天數/開啟次數、討論區app發文數/回文數、居住地
# 註：以上數字皆統計近三個月即可
# 
# 2. 網頁版討論區使用者
#  
#    a. 分享者
#    條件：
#    - 近三個月網頁版討論區發文數於前 50%或回文數於前 50%
#    - 近三個月網站登入天數大於30天
# 欄位：帳號、暱稱、網站登入天數、網頁版討論區發文數/回文數、網頁版討論區觀看文章篇數、討論區app登入天數/開啟次數、居住地
# 註：以上數字皆統計近三個月即可
# 
#    b. 觀看者
#    條件：
#    - 近三個月討論區討論區觀看文章數於前50%
#    - 近三個月網站登入天數大於 30天
# 欄位：帳號、暱稱、網站登入天數、網頁版討論區發文數/回文數、網頁版討論區觀看文章篇數、討論區app登入天數/開啟次數、居住地
# 註：以上數字皆統計近三個月即可
# =================================================================================================

# 先跑居住地
# code: 1715~1763
# 需匯入:
#     (1)exchange_validate
#     (2)user_living_city
#     (3)udata

# 1. 討論區APP使用者

CREATE TABLE plsport_playsport._app_action_log_0 engine = myisam
SELECT * FROM plsport_playsport.app_action_log
WHERE datetime between subdate(now(),91) AND now();

CREATE TABLE plsport_playsport._app_action_log_1 engine = myisam
SELECT *
FROM plsport_playsport._app_action_log_0
WHERE action in (1,2,3,'login','postArticle','replyArticle') # 討論區行為(app_action_log在中間有大改版過)
AND userid is not null; # 一定要有userid才算有登入

CREATE TABLE plsport_playsport._app_action_log_2 engine = myisam
SELECT id, app, os, appVersion, userid, action, (case when (action in (1,2,3)) then action else 0 end) as action1,
                                                (case when (action = 'postArticle') then 1
                                                      when (action = 'replyArticle') then 2
                                                      when (action = 'login') then 3  else 0 end) as action2,
remark, datetime, deviceid, abtestGroup, deviceModel, deviceOsVersion, longitude, latitude, ip
FROM plsport_playsport._app_action_log_1
ORDER BY datetime DESC;

CREATE TABLE plsport_playsport._app_action_log_3 engine = myisam
SELECT  id, app, os, appVersion, userid, (action1 + action2) as action, remark, datetime, deviceid, abtestGroup, deviceModel, deviceOsVersion, longitude, latitude, ip 
FROM plsport_playsport._app_action_log_2;

CREATE TABLE plsport_playsport._app_action_log_4 engine = myisam
SELECT a.userid, sum(a.post) as post, sum(a.reply) as reply, sum(a.login) as login
FROM (
    SELECT userid, (case when (action=1) then 1 else 0 end) as post,
                   (case when (action=2) then 1 else 0 end) as reply,
                   (case when (action=3) then 1 else 0 end) as login
    FROM plsport_playsport._app_action_log_3) as a
GROUP BY a.userid;

CREATE TABLE plsport_playsport._app_action_log_5 engine = myisam
SELECT a.userid, b.nickname, a.post, a.reply, a.login 
FROM plsport_playsport._app_action_log_4 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

CREATE TABLE plsport_playsport._app_login_date_count engine = myisam #使用APP的天數
SELECT b.userid, count(b.d) as login_date_count
FROM (
    SELECT a.userid, a.d, count(a.d) as c 
    FROM (
        SELECT userid, date(datetime) as d 
        FROM plsport_playsport._app_action_log_1) as a
    GROUP BY a.userid, a.d) as b
GROUP BY b.userid;

CREATE TABLE plsport_playsport._app_action_log_6 engine = myisam
SELECT a.userid, a.nickname, b.login_date_count, a.login, a.post, a.reply 
FROM plsport_playsport._app_action_log_5 a LEFT JOIN plsport_playsport._app_login_date_count b on a.userid = b.userid;


# 新發現, Calculate percentile in MySQL based on totals, 直接用SQL計算percentile

# (1)計算post percentile
CREATE TABLE plsport_playsport._app_action_log_6_1 engine = myisam
SELECT userid, nickname, login_date_count, login, post, reply, round((cnt-rank+1)/cnt,2) as post_percentile 
FROM (SELECT userid, nickname, login_date_count, login, post, reply, @curRank := @curRank + 1 AS rank
      FROM plsport_playsport._app_action_log_6, (SELECT @curRank := 0) r
      WHERE post > 0
      ORDER BY post DESC) as dt, 
     (SELECT count(distinct userid) as cnt FROM plsport_playsport._app_action_log_6
      WHERE post > 0) as ct;

# (2)計算reply percentile
CREATE TABLE plsport_playsport._app_action_log_6_2 engine = myisam
SELECT userid, nickname, login_date_count, login, post, reply, round((cnt-rank+1)/cnt,2) as reply_percentile 
FROM (SELECT userid, nickname, login_date_count, login, post, reply, @curRank := @curRank + 1 AS rank
      FROM plsport_playsport._app_action_log_6, (SELECT @curRank := 0) r
      WHERE reply > 0
      ORDER BY reply DESC) as dt, 
     (SELECT count(distinct userid) as cnt FROM plsport_playsport._app_action_log_6
      WHERE reply > 0) as ct;

CREATE TABLE plsport_playsport._app_action_log_7 engine = myisam
SELECT a.userid, a.nickname, a.login_date_count, a.login, a.post, b.post_percentile, a.reply 
FROM plsport_playsport._app_action_log_6 a LEFT JOIN plsport_playsport._app_action_log_6_1 b on a.userid = b.userid;

CREATE TABLE plsport_playsport._app_action_log_8 engine = myisam
SELECT a.userid, a.nickname, a.login_date_count, a.login, a.post, a.post_percentile, a.reply, b.reply_percentile
FROM plsport_playsport._app_action_log_7 a LEFT JOIN plsport_playsport._app_action_log_6_2 b on a.userid = b.userid;

        ALTER TABLE plsport_playsport._city_info_ok_with_chinese ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._app_action_log_8 ADD INDEX (`userid`);


CREATE TABLE plsport_playsport._app_action_log_9 engine = myisam
SELECT a.userid, a.nickname, a.login_date_count as login_days, a.login, a.post, a.post_percentile, a.reply, a.reply_percentile, b.city1 as city 
FROM plsport_playsport._app_action_log_8 a LEFT JOIN plsport_playsport._city_info_ok_with_chinese b on a.userid = b.userid;

        CREATE TABLE plsport_playsport._last_signin_app engine = myisam # 最近一次登入(討論區APP)
        SELECT userid, max(datetime) as last_signin
        FROM plsport_playsport._app_action_log_1
        GROUP BY userid;

        ALTER TABLE plsport_playsport._app_action_log_9 ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._last_signin_app ADD INDEX (`userid`);

# 完成
CREATE TABLE plsport_playsport._app_action_log_10 engine = myisam
SELECT a.userid, a.nickname, a.login_days, a.login, a.post, a.post_percentile, a.reply, a.reply_percentile, a.city, date(b.last_signin) as last_signin
FROM plsport_playsport._app_action_log_9 a LEFT JOIN plsport_playsport._last_signin_app b on a.userid = b.userid;

rename TABLE plsport_playsport._app_action_log_10 to plsport_playsport._full_list_forum_app_user;

drop TABLE plsport_playsport._app_action_log_0,plsport_playsport._app_action_log_1,plsport_playsport._app_action_log_2;
drop TABLE plsport_playsport._app_action_log_3,plsport_playsport._app_action_log_4,plsport_playsport._app_action_log_5;
drop TABLE plsport_playsport._app_action_log_6,plsport_playsport._app_action_log_6_1,plsport_playsport._app_action_log_6_2;
drop TABLE plsport_playsport._app_action_log_7,plsport_playsport._app_action_log_8,plsport_playsport._app_action_log_9;

update plsport_playsport._full_list_forum_app_user SET nickname = TRIM(nickname);             #刪掉空白字完
update plsport_playsport._full_list_forum_app_user SET nickname = replace(nickname, '.',''); 
update plsport_playsport._full_list_forum_app_user SET nickname = replace(nickname, ';','');
update plsport_playsport._full_list_forum_app_user SET nickname = replace(nickname, '/','');
update plsport_playsport._full_list_forum_app_user SET nickname = replace(nickname, '\\','_');
update plsport_playsport._full_list_forum_app_user SET nickname = replace(nickname, '"','');
update plsport_playsport._full_list_forum_app_user SET nickname = replace(nickname, '&','');
update plsport_playsport._full_list_forum_app_user SET nickname = replace(nickname, '#','');
update plsport_playsport._full_list_forum_app_user SET nickname = replace(nickname, ' ','');
update plsport_playsport._full_list_forum_app_user SET nickname = replace(nickname, '\n','');
update plsport_playsport._full_list_forum_app_user SET nickname = replace(nickname, '\b','');
update plsport_playsport._full_list_forum_app_user SET nickname = replace(nickname, '\t','');

CREATE TABLE plsport_playsport._full_list_forum_app_user_1 engine = myisam
SELECT * 
FROM plsport_playsport._full_list_forum_app_user
WHERE login_days > 29;

drop TABLE plsport_playsport._full_list_forum_app_user;

SELECT '帳號', '暱稱', 'app登入天數', 'app開啟次數', 'app發文數', '%', 'app回文數', '%', '居住地', '最後一次打開app' UNION (
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_full_list_forum_app_user_1.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._full_list_forum_app_user_1);



# 2. 網頁版討論區使用者

# 網站登入天數
CREATE TABLE plsport_playsport._signin_days engine = myisam
SELECT userid, date(signin_time) as ad
FROM plsport_playsport.member_signin_log_archive
WHERE signin_time between subdate(now(),91) AND now();

CREATE TABLE plsport_playsport._signin_days_1 engine = myisam
SELECT userid, ad as d, count(userid) as c
FROM plsport_playsport._signin_days
GROUP BY userid, ad;

CREATE TABLE plsport_playsport._signin_days_2 engine = myisam
SELECT userid, count(d) as signin_days 
FROM plsport_playsport._signin_days_1
GROUP BY userid;

drop TABLE plsport_playsport._signin_days, plsport_playsport._signin_days_1;
rename TABLE plsport_playsport._signin_days_2 to plsport_playsport._signin_days;

# 網頁版討論區發文數/回文數
        # ---post---
        CREATE TABLE plsport_playsport._post_count engine = myisam
        SELECT subjectid, postuser as userid, posttime as time  
        FROM plsport_playsport.forum
        WHERE posttime between subdate(now(),91) AND now();

        CREATE TABLE plsport_playsport._post_count_1 engine = myisam
        SELECT userid, count(subjectid) as post_count 
        FROM plsport_playsport._post_count
        GROUP BY userid;

        drop TABLE plsport_playsport._post_count;
        rename TABLE plsport_playsport._post_count_1 to plsport_playsport._post_count;

        # ---reply---
        CREATE TABLE plsport_playsport._reply_count engine = myisam
        SELECT userid, count(articleid) as reply_count
        FROM plsport_playsport.forumcontent
        WHERE postdate between subdate(now(),91) AND now()
        GROUP BY userid;
        
                # 重跑上面的SQL直到_alpp_action_log_5
                # (1)討論區的貼文數要扣掉APP的貼文數
                CREATE TABLE plsport_playsport._post_count_1 engine = myisam
                SELECT d.userid, (case when (d.post_count<0) then 0 else d.post_count end) as post_count
                FROM (
                    SELECT c.userid, (c.post_count-c.post) as post_count
                    FROM (
                        SELECT a.userid, a.post_count, (case when (b.post is null) then 0 else b.post end) as post
                        FROM plsport_playsport._post_count a LEFT JOIN plsport_playsport._app_action_log_5 b on a.userid = b.userid) as c) as d;
                        
                drop TABLE plsport_playsport._post_count;
                rename TABLE plsport_playsport._post_count_1 to plsport_playsport._post_count;    
                
                # (1)討論區的回文數要扣掉APP的回文數     
                CREATE TABLE plsport_playsport._reply_count_1 engine = myisam
                SELECT d.userid, (case when (d.reply_count<0) then 0 else d.reply_count end) as reply_count
                FROM (
                    SELECT c.userid, (c.reply_count-c.reply) as reply_count
                    FROM (
                        SELECT a.userid, a.reply_count, (case when (b.reply is null) then 0 else b.reply end) as reply
                        FROM plsport_playsport._reply_count a LEFT JOIN plsport_playsport._app_action_log_5 b on a.userid = b.userid) as c) as d;    
                        
                drop TABLE plsport_playsport._reply_count;
                rename TABLE plsport_playsport._reply_count_1 to plsport_playsport._reply_count;

        # 計算出貼文的%數
        CREATE TABLE plsport_playsport._post_count_with_percentile engine = myisam
        SELECT userid, post_count, round((cnt-rank+1)/cnt,2) as post_percentile
        FROM (SELECT userid, post_count, @curRank := @curRank + 1 AS rank
              FROM plsport_playsport._post_count, (SELECT @curRank := 0) r
              WHERE post_count > 0 # 0篇的不算
              ORDER BY post_count DESC) as dt,
             (SELECT count(distinct userid) as cnt FROM plsport_playsport._post_count) as ct;

        # 計算出回文的%數
        CREATE TABLE plsport_playsport._reply_count_with_percentile engine = myisam
        SELECT userid, reply_count, round((cnt-rank+1)/cnt,2) as reply_percentile
        FROM (SELECT userid, reply_count, @curRank := @curRank + 1 AS rank
              FROM plsport_playsport._reply_count, (SELECT @curRank := 0) r
              WHERE reply_count > 0 # 0篇的不算
              ORDER BY reply_count DESC) as dt,
             (SELECT count(distinct userid) as cnt FROM plsport_playsport._reply_count) as ct;


# 處理網頁版討論區觀看文章篇數(重覆不算)
CREATE TABLE actionlog._forumdetail_pv_0 engine = myisam
SELECT * FROM actionlog.action_201411 WHERE uri LIKE '%forumdetail%' AND userid <> '';
INSERT IGNORE INTO actionlog._forumdetail_pv_0 
SELECT * FROM actionlog.action_201412 WHERE uri LIKE '%forumdetail%' AND userid <> '';
INSERT IGNORE INTO actionlog._forumdetail_pv_0 
SELECT * FROM actionlog.action_201501 WHERE uri LIKE '%forumdetail%' AND userid <> '';
INSERT IGNORE INTO actionlog._forumdetail_pv_0 
SELECT * FROM actionlog.action_201502 WHERE uri LIKE '%forumdetail%' AND userid <> '';

CREATE TABLE actionlog._forumdetail_pv_1 engine = myisam
SELECT userid, uri, time, platform_type
FROM actionlog._forumdetail_pv_0
WHERE time between subdate(now(),91) AND now();

CREATE TABLE actionlog._forumdetail_pv_2 engine = myisam
SELECT userid, uri, time, (case when (platform_type=1) then 1 else 2 end) as platform 
FROM actionlog._forumdetail_pv_1;

CREATE TABLE actionlog._forumdetail_pv_3 engine = myisam # 開始把subjectid給抽出來
SELECT a.userid, a.uri, (case when (locate('&',a.s)=0) then a.s else substr(a.s,1,locate('&',a.s)-1) end) as s, a.time, a.platform
FROM (
    SELECT userid, uri, substr(uri,locate('subjectid=',uri)+10, length(uri)) as s, time, platform
    FROM actionlog._forumdetail_pv_2) as a;

        CREATE TABLE actionlog._forumdetail_pv_3_1 engine = myisam
        SELECT userid, uri, s, length(s) as c, time, platform 
        FROM actionlog._forumdetail_pv_3;

        CREATE TABLE actionlog._forumdetail_pv_3_2 engine = myisam # 只留下len(subjectid) = 15
        SELECT userid, uri, s, time, platform  
        FROM actionlog._forumdetail_pv_3_1 WHERE c = 15;

                ALTER TABLE actionlog._forumdetail_pv_3_2 ADD INDEX (`userid`);
                ALTER TABLE actionlog._forumdetail_pv_3_2 CHANGE `s` `s` VARCHAR(17) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL;
                ALTER TABLE actionlog._forumdetail_pv_3_2 ADD INDEX (`s`);

        # 重要重要重要!!! note: it takes around 34~46 mins
        CREATE TABLE actionlog._forumdetail_pv_3_3 engine = myisam
        SELECT userid, s # s:subjectid
        FROM actionlog._forumdetail_pv_3_2
        GROUP BY userid, s;

        CREATE TABLE actionlog._view_post_count engine = myisam
        SELECT userid, count(s) as view_post_count 
        FROM actionlog._forumdetail_pv_3_3
        GROUP BY userid;

        # 計算出回文的%數
        CREATE TABLE plsport_playsport._view_post_count_with_percentile engine = myisam
        SELECT userid, view_post_count, round((cnt-rank+1)/cnt,2) as view_post_percentile
        FROM (SELECT userid, view_post_count, @curRank := @curRank + 1 AS rank
              FROM actionlog._view_post_count, (SELECT @curRank := 0) r
              ORDER BY view_post_count DESC) as dt,
             (SELECT count(distinct userid) as cnt FROM actionlog._view_post_count) as ct;

# 討論區app登入天數/開啟次數: 可以直接使用 plsport_playsport._app_action_log_3

# 開始製作完整名單

CREATE TABLE plsport_playsport._full_list_forum_web_user_0 engine = myisam
SELECT c.userid, c.nickname, c.signin_days, d.post_count, d.post_percentile
FROM 
   (SELECT a.userid, b.nickname, a.signin_days 
    FROM plsport_playsport._signin_days a LEFT JOIN plsport_playsport.member b on a.userid = b.userid) as c
    LEFT JOIN plsport_playsport._post_count_with_percentile as d on c.userid = d.userid;

CREATE TABLE plsport_playsport._full_list_forum_web_user_1 engine = myisam
SELECT a.userid, a.nickname, a.signin_days, a.post_count, a.post_percentile, b.reply_count, b.reply_percentile
FROM plsport_playsport._full_list_forum_web_user_0 a LEFT JOIN plsport_playsport._reply_count_with_percentile b on a.userid = b.userid;

        ALTER TABLE plsport_playsport._full_list_forum_web_user_1 convert to character SET utf8 collate utf8_general_ci;
        ALTER TABLE plsport_playsport._view_post_count_with_percentile convert to character SET utf8 collate utf8_general_ci;
        ALTER TABLE plsport_playsport._full_list_forum_web_user_1 ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._view_post_count_with_percentile ADD INDEX (`userid`);

CREATE TABLE plsport_playsport._full_list_forum_web_user_2 engine = myisam
SELECT a.userid, a.nickname, a.signin_days, a.post_count, a.post_percentile, a.reply_count, a.reply_percentile, 
       b.view_post_count, b.view_post_percentile
FROM plsport_playsport._full_list_forum_web_user_1 a LEFT JOIN plsport_playsport._view_post_count_with_percentile b on a.userid = b.userid;

CREATE TABLE plsport_playsport._full_list_forum_web_user_3 engine = myisam
SELECT a.userid, a.nickname, a.signin_days, a.post_count, a.post_percentile, a.reply_count, a.reply_percentile,
       a.view_post_count, a.view_post_percentile, b.login_date_count, b.login
FROM plsport_playsport._full_list_forum_web_user_2 a LEFT JOIN plsport_playsport._app_action_log_6 b on a.userid = b.userid;

CREATE TABLE plsport_playsport._full_list_forum_web_user_4 engine = myisam
SELECT a.userid, a.nickname, a.signin_days, a.post_count, a.post_percentile, a.reply_count, a.reply_percentile,
       a.view_post_count, a.view_post_percentile, a.login_date_count, a.login, b.city1 as city
FROM plsport_playsport._full_list_forum_web_user_3 a LEFT JOIN plsport_playsport._city_info_ok_with_chinese b on a.userid = b.userid
WHERE a.signin_days > 29;

        CREATE TABLE plsport_playsport._last_signin engine = myisam # 最近一次登入
        SELECT userid, max(signin_time) as last_signin
        FROM plsport_playsport.member_signin_log_archive
        GROUP BY userid;

        ALTER TABLE plsport_playsport._last_signin convert to character SET utf8 collate utf8_general_ci;
        ALTER TABLE plsport_playsport._last_signin ADD INDEX (`userid`);

CREATE TABLE plsport_playsport._full_list_forum_web_user_temp engine = myisam
SELECT a.userid, a.nickname, a.signin_days, a.post_count, a.post_percentile, a.reply_count, a.reply_percentile,
       a.view_post_count, a.view_post_percentile, a.login_date_count, a.login, a.city, date(b.last_signin) as last_signin
FROM plsport_playsport._full_list_forum_web_user_4 a LEFT JOIN plsport_playsport._last_signin b on a.userid = b.userid;

rename TABLE plsport_playsport._full_list_forum_web_user_temp to plsport_playsport._full_list_forum_web_user;
drop TABLE plsport_playsport._full_list_forum_web_user_0, plsport_playsport._full_list_forum_web_user_1;
drop TABLE plsport_playsport._full_list_forum_web_user_2, plsport_playsport._full_list_forum_web_user_3;

update plsport_playsport._full_list_forum_web_user SET nickname            = TRIM(nickname);             #刪掉空白字完
update plsport_playsport._full_list_forum_web_user SET nickname = replace(nickname, '.',''); 
update plsport_playsport._full_list_forum_web_user SET nickname = replace(nickname, ';','');
update plsport_playsport._full_list_forum_web_user SET nickname = replace(nickname, '/','');
update plsport_playsport._full_list_forum_web_user SET nickname = replace(nickname, '\\','_');
update plsport_playsport._full_list_forum_web_user SET nickname = replace(nickname, '"','');
update plsport_playsport._full_list_forum_web_user SET nickname = replace(nickname, '&','');
update plsport_playsport._full_list_forum_web_user SET nickname = replace(nickname, '#','');
update plsport_playsport._full_list_forum_web_user SET nickname = replace(nickname, ' ','');
update plsport_playsport._full_list_forum_web_user SET nickname = replace(nickname, '\n','');
update plsport_playsport._full_list_forum_web_user SET nickname = replace(nickname, '\b','');
update plsport_playsport._full_list_forum_web_user SET nickname = replace(nickname, '\t','');


SELECT '帳號', '暱稱', '網站登入天數', '網頁版討論區發文數', '%', '網頁版討論區回文數', '%', '網頁版討論區觀看文章篇數', '%',
       'app登入天數', 'app開啟次數', '居住地', '最後登入' UNION (
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_full_list_forum_web_user.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._full_list_forum_web_user);



# 試著加入座標

CREATE TABLE plsport_playsport._member_last_ip engine = myisam
SELECT userid, ip, max(signin_time) as t 
FROM plsport_playsport.member_signin_log_archive
GROUP BY userid, ip;







# 2014-12-08所做的修正, 阿達發現名單有問題, 因為討論區的行為要扣掉APP的行為才是純討論區的行為
# -------------------------2015-01-29補充----------------------------------------------------
# 當時是直接在excel裡先計算正確, 然後再獨立匯成csv再匯入Mysql單獨重算貼文和回文的行為
# 這次在跑上面的名單時, 注意有計算正確不用再跑下面的步驟.
# 要把(1)網頁版討論區的名單LEFT JOIN討論區APP的名單, 再把(網頁版的發回文數-APP討論區的發回文數)
# 才是正確的"純"網頁版討論區的發/回文數!

CREATE TABLE _sharer_post engine = myisam
SELECT * 
FROM csv_db.sharer
WHERE post >0;

CREATE TABLE _sharer_reply engine = myisam
SELECT * 
FROM csv_db.sharer
WHERE reply >0;

CREATE TABLE csv_db._sharer_post_with_percentile engine = myisam
SELECT userid, post, round((cnt-rank+1)/cnt,2) as post_percentile
FROM (SELECT userid, post, @curRank := @curRank + 1 AS rank
      FROM csv_db._sharer_post, (SELECT @curRank := 0) r
      ORDER BY post DESC) as dt,
     (SELECT count(distinct userid) as cnt FROM csv_db._sharer_post) as ct;

CREATE TABLE csv_db._sharer_reply_with_percentile engine = myisam
SELECT userid, reply, round((cnt-rank+1)/cnt,2) as reply_percentile
FROM (SELECT userid, reply, @curRank := @curRank + 1 AS rank
      FROM csv_db._sharer_reply, (SELECT @curRank := 0) r
      ORDER BY reply DESC) as dt,
     (SELECT count(distinct userid) as cnt FROM csv_db._sharer_reply) as ct;



# =================================================================================================
# 要製作新的台灣經計研究, 增加(1)討論區pv (2)即時比分pv (3)台灣運彩營收 2014-12-03
# 計算跑太久, 等新硬碟來了再處理這個任務
# =================================================================================================

CREATE TABLE actionlog._u_livescore engine = myisam
SELECT * FROM actionlog.action_201401 WHERE uri LIKE '%/livescore%';
INSERT IGNORE INTO actionlog._u_livescore SELECT * FROM actionlog.action_201402 WHERE uri LIKE '%/livescore%';
INSERT IGNORE INTO actionlog._u_livescore SELECT * FROM actionlog.action_201403 WHERE uri LIKE '%/livescore%';
INSERT IGNORE INTO actionlog._u_livescore SELECT * FROM actionlog.action_201404 WHERE uri LIKE '%/livescore%';
INSERT IGNORE INTO actionlog._u_livescore SELECT * FROM actionlog.action_201405 WHERE uri LIKE '%/livescore%';
INSERT IGNORE INTO actionlog._u_livescore SELECT * FROM actionlog.action_201406 WHERE uri LIKE '%/livescore%';
INSERT IGNORE INTO actionlog._u_livescore SELECT * FROM actionlog.action_201407 WHERE uri LIKE '%/livescore%';
INSERT IGNORE INTO actionlog._u_livescore SELECT * FROM actionlog.action_201408 WHERE uri LIKE '%/livescore%';
INSERT IGNORE INTO actionlog._u_livescore SELECT * FROM actionlog.action_201409 WHERE uri LIKE '%/livescore%';
INSERT IGNORE INTO actionlog._u_livescore SELECT * FROM actionlog.action_201410 WHERE uri LIKE '%/livescore%';
INSERT IGNORE INTO actionlog._u_livescore SELECT * FROM actionlog.action_20141130 WHERE uri LIKE '%/livescore%';

CREATE TABLE actionlog._u_forum engine = myisam
SELECT * FROM actionlog.action_201401 WHERE uri LIKE '%/forum%';
INSERT IGNORE INTO actionlog._u_forum SELECT * FROM actionlog.action_201402 WHERE uri LIKE '%/forum%';
INSERT IGNORE INTO actionlog._u_forum SELECT * FROM actionlog.action_201403 WHERE uri LIKE '%/forum%';
INSERT IGNORE INTO actionlog._u_forum SELECT * FROM actionlog.action_201404 WHERE uri LIKE '%/forum%';
INSERT IGNORE INTO actionlog._u_forum SELECT * FROM actionlog.action_201405 WHERE uri LIKE '%/forum%';
INSERT IGNORE INTO actionlog._u_forum SELECT * FROM actionlog.action_201406 WHERE uri LIKE '%/forum%';
INSERT IGNORE INTO actionlog._u_forum SELECT * FROM actionlog.action_201407 WHERE uri LIKE '%/forum%';
INSERT IGNORE INTO actionlog._u_forum SELECT * FROM actionlog.action_201408 WHERE uri LIKE '%/forum%';
INSERT IGNORE INTO actionlog._u_forum SELECT * FROM actionlog.action_201409 WHERE uri LIKE '%/forum%';
INSERT IGNORE INTO actionlog._u_forum SELECT * FROM actionlog.action_201410 WHERE uri LIKE '%/forum%';
INSERT IGNORE INTO actionlog._u_forum SELECT * FROM actionlog.action_20141130 WHERE uri LIKE '%/forum%';


# =================================================================================================
# 任務: [201408-B-4]優化討論區手機版發文功能-手機發文介面ABtesting [新建] (靜怡)
# http://pm.playsport.cc/index.php/tasksComments?tasksId=3925&projectId=11
# 說明
# 目的：了解新版手機發文介面是否吸引使用者
# 目標：1.發文數增加2.問卷滿意度達4
#  
# 內容
# - 測試時間：12/5~12/24
# - 設定測試組別
# - 觀察指標：(1)發文數 (2)問卷滿意度
#                          http://www.playsport.cc/questionnaire.php?question=forumPostMobile&action=statistics
# - 報告時間：12/31(提前1天至30日)
# =================================================================================================

# 以下是檢察a/b tesing分組的部分, 結果如下
# http://pm.playsport.cc/index.php/tasksComments?tasksId=3925&projectId=11
CREATE TABLE plsport_playsport._forum engine = myisam
SELECT a.subjectid, a.subject, a.postuser, a.posttime, b.post_FROM
FROM plsport_playsport.forum a LEFT JOIN plsport_playsport.abtesting_forum_post_enhanced b on a.subjectid = b.subjectid
WHERE b.post_FROM is not null;

CREATE TABLE plsport_playsport._forum_1 engine = myisam
SELECT a.subjectid, a.subject, (b.id%20)+1 as g, a.postuser, a.posttime, a.post_FROM 
FROM plsport_playsport._forum a LEFT JOIN plsport_playsport.member b on a.postuser = b.userid;

CREATE TABLE plsport_playsport._forum_2 engine = myisam
SELECT subjectid, subject, g, (case when (g<11) then 'a' else 'b' end) as abtest, postuser, posttime , post_FROM  
FROM plsport_playsport._forum_1;

# 最後一次撈是完整的12/5~12/29

        # 統計
        SELECT abtest, post_FROM, count(postuser) as c 
        FROM plsport_playsport._forum_2
        GROUP BY abtest, post_FROM;

            SELECT * FROM plsport_playsport._forum_2
            WHERE abtest = 'a' AND post_FROM = '1';

        SELECT a.postuser, count(a.g) as c
        FROM (
            SELECT * FROM plsport_playsport._forum_2
            WHERE abtest = 'a' AND post_FROM = '1') as a
        GROUP BY a.postuser;

# ..................................................... 
# TO EDDY
# 補充說明
# - 因手機版有提供電腦版的連結，所以該狀況在統計時晴排除
# - 另提供從手機版點電腦版的狀況
# ..................................................... 

# 先dump以下:
#   (1)forum
#   (2)abtesting_forum_post_enhanced
#   (3)member

# 先跑上面的跑到_forum_2完成

    # 2組各有多人有po過文? a:918 b:909
    SELECT a.abtest, count(a.postuser) as poster_count
    FROM (
        SELECT abtest, postuser, count(subjectid) as c 
        FROM plsport_playsport._forum_2
        GROUP BY abtest, postuser) as a
    GROUP BY a.abtest;

            # a組有多少人用新界面回文 353
            SELECT count(a.postuser)
            FROM (
                SELECT abtest, postuser
                FROM plsport_playsport._forum_2
                WHERE abtest = 'a' AND post_FROM = 2
                GROUP BY abtest, postuser) as a;

            # a組有多少人用舊界面回文 72
            SELECT count(a.postuser)
            FROM (
                SELECT abtest, postuser
                FROM plsport_playsport._forum_2
                WHERE abtest = 'a' AND post_FROM = 1
                GROUP BY abtest, postuser) as a;

            # b組有多少人用舊界面回文 388
            SELECT count(a.postuser)
            FROM (
                SELECT abtest, postuser
                FROM plsport_playsport._forum_2
                WHERE abtest = 'b' AND post_FROM = 1
                GROUP BY abtest, postuser) as a;

# 有多少人用了新版也用了舊版? 28
SELECT count(a.postuser)
FROM (SELECT abtest, postuser
      FROM plsport_playsport._forum_2
      WHERE abtest = 'a' AND post_FROM = 2
      GROUP BY abtest, postuser) as a inner join 
            (SELECT abtest, postuser
            FROM plsport_playsport._forum_2
            WHERE abtest = 'a' AND post_FROM = 1
            GROUP BY abtest, postuser) as b on a.postuser = b.postuser;

# a組共有幾個人發過文? 397
SELECT abtest, postuser
FROM plsport_playsport._forum_2
WHERE abtest = 'a' AND post_FROM > 0
GROUP BY abtest, postuser;


# 製作名單1 
# (1) 先撈出a組用新版發文界面的人
        CREATE TABLE plsport_playsport._list_1 engine = myisam
        SELECT abtest, postuser, count(subjectid) as post_count
        FROM plsport_playsport._forum_2
        WHERE abtest = 'a' AND post_FROM = 2 # 新版
        GROUP BY abtest, postuser;
# (2) 再INSERT b組用舊版發文界面的人
        INSERT IGNORE INTO plsport_playsport._list_1
        SELECT abtest, postuser, count(subjectid) as post_count
        FROM plsport_playsport._forum_2
        WHERE abtest = 'b' AND post_FROM = 1 # 舊版
        GROUP BY abtest, postuser;

# 輸出給.txt給R用
SELECT 'abtest', 'postuser', 'post_count' UNION (
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_list_1.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._list_1);


# 製作名單2
# (1) 先撈出a組用新版發文界面的人
        CREATE TABLE plsport_playsport._list_2 engine = myisam
        SELECT abtest, postuser, count(subjectid) as post_count
        FROM plsport_playsport._forum_2
        WHERE abtest = 'a' AND post_FROM in (1,2)# 不論新版還舊版
        GROUP BY abtest, postuser;
# (2) 再INSERT b組用舊版發文界面的人
        INSERT IGNORE INTO plsport_playsport._list_2
        SELECT abtest, postuser, count(subjectid) as post_count
        FROM plsport_playsport._forum_2
        WHERE abtest = 'b' AND post_FROM = 1 # 舊版
        GROUP BY abtest, postuser;

# 輸出給.txt給R用
SELECT 'abtest', 'postuser', 'post_count' UNION (
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_list_2.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._list_2);


# =================================================================================================
# 任務: 分析文評分排行榜統計 [新建] (福利班) 2014-12-16
# http://pm.playsport.cc/index.php/tasksComments?tasksId=3956&projectId=11
# 
# 要依以下條件，嘗試為分析文評分產生排行榜
# 時間：11/28 ~ 12/12前皆可，請於12/17 社群會議時報告
# 
# 規則條件：
# 1. 每天有 N 個人以上的評分的文章才計入
# 2. 依規則1，14天內取分數最高的10天
# 3. 將兩週內的10篇文章的分數平均
# 4. 依平均分數排行，最少產生5名
# 
# 需求：
# 1. 請依統計的這段期間內，嘗試找出最適當的N值是多少人
# 2. 請依N個人，產生排行榜供參考，看誰在榜上面
# =================================================================================================

# 先匯入forum_analysis_score

CREATE TABLE plsport_playsport._forum engine = myisam
SELECT subjectid, subject, postuser, posttime
FROM plsport_playsport.forum
WHERE date(posttime) between '2014-11-28' AND '2014-12-11';

CREATE TABLE plsport_playsport._forum_analysis_score engine = myisam
SELECT subjectid, count(userid) as score_count, round(avg(score),2) as score_avg 
FROM plsport_playsport.forum_analysis_score
GROUP BY subjectid;

CREATE TABLE plsport_playsport._forum_with_score_0 engine = myisam
SELECT a.subjectid, a.postuser, a.posttime, b.score_count, b.score_avg
FROM plsport_playsport._forum a LEFT JOIN plsport_playsport._forum_analysis_score b on a.subjectid = b.subjectid
WHERE b.score_count is not null;

CREATE TABLE plsport_playsport._forum_with_score_1 engine = myisam
SELECT a.subjectid, a.postuser, b.nickname, a.posttime, a.score_count, a.score_avg 
FROM plsport_playsport._forum_with_score_0 a LEFT JOIN plsport_playsport.member b on a.postuser = b.userid;

SELECT *
FROM (
    SELECT nickname, count(subjectid) as analysis_post_count
    FROM plsport_playsport._forum_with_score_1
    WHERE score_count >= 1 # 要有n個人評分
    GROUP BY nickname) as a
WHERE a.analysis_post_count >= 10; # 要大於m篇分析文

SELECT *
FROM (
    SELECT nickname, round(avg(score_count),1) as score_count, round(avg(score_avg),2) as score_avg, count(subjectid) as analysis_post_count
    FROM plsport_playsport._forum_with_score_1
    WHERE score_count >= 10 # 要有n個人評分
    GROUP BY nickname) as a
WHERE a.analysis_post_count >= 10 # 要大於m篇分析文
ORDER BY a.score_avg DESC;


# =================================================================================================
# 任務: [201410-A-6] NBA即時比分訪談 - 問卷報告 [新建] (阿達) 2014-12-18
# http://pm.playsport.cc/index.php/tasksComments?tasksId=3997&projectId=11
# 說明
#  
# 依據不同裝置做問卷結果報告，並排除無效問卷
# 負責人：Eddy
# 時間：12/22(一)
# 附件：問卷結果、問卷網址
# 資料表: questionnaire_livescoreNbaViewImprovement_answer
#  
# 問卷報告
# 1. 分成手機、電腦使用者
# 2. 排除無效問卷
# =================================================================================================

# 要筆對action_log中填問券者是用什麼裝置填寫問券12/16~12/18
CREATE TABLE plsport_playsport._log engine = myisam
SELECT userid, uri, time, (case when (platform_type<2) then 'pc' else 'mobile' end) as p
FROM actionlog.action_201412
WHERE userid <> ''
AND uri LIKE '%livescoreNbaViewImprovement%';

CREATE TABLE plsport_playsport._log1 engine = myisam
SELECT userid, p
FROM plsport_playsport._log
GROUP BY userid, p;

CREATE TABLE plsport_playsport._list_1 engine = myisam
SELECT * FROM plsport_playsport.questionnaire_livescorenbaviewimprovement_answer
WHERE question01 <> '1,2,3,4';

CREATE TABLE plsport_playsport._list_2 engine = myisam
SELECT * FROM plsport_playsport._list_1
WHERE spend_minute >= 0.5 ;

        ALTER TABLE plsport_playsport._log1   convert to character SET utf8 collate utf8_general_ci;
        ALTER TABLE plsport_playsport._list_2 convert to character SET utf8 collate utf8_general_ci;

CREATE TABLE plsport_playsport._list_3 engine = myisam
SELECT a.userid, date(a.write_time) as d, a.question01, a.question02, a.question03, a.question04, b.p
FROM plsport_playsport._list_2 a LEFT JOIN plsport_playsport._log1 b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_4 engine = myisam
SELECT userid, d, 
       (case when (question01 LIKE '%1%') then 1 else 0 end) as q1,
       (case when (question01 LIKE '%2%') then 1 else 0 end) as q2,
       (case when (question01 LIKE '%3%') then 1 else 0 end) as q3,
       (case when (question01 LIKE '%4%') then 1 else 0 end) as q4,
       question02, question03, question04,p
FROM plsport_playsport._list_3;

# 問題1
SELECT p, sum(q1), sum(q2), sum(q3), sum(q4)
FROM plsport_playsport._list_4
GROUP BY p;

# 問題2
SELECT p, question02, count(userid) as c  
FROM plsport_playsport._list_4
WHERE question02 <> ''
GROUP BY p, question02;

# 問題3
SELECT p, question03, count(userid) as c  
FROM plsport_playsport._list_4
WHERE question03 <> ''
GROUP BY p, question03;

# 問題4
SELECT p, question04, count(userid) as c  
FROM plsport_playsport._list_4
WHERE question04 <> ''
GROUP BY p, question04;


# =================================================================================================
# 任務: [201404-B-3] 手機網頁版header優化-MVP測試名單手機網頁版header優化-MVP測試名單 [新建] (靜怡) 2014-12-18
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4004&projectId=11
# 提供測試名單
#  
# 需求
# - 族群:D2、D3、D5(不用標上)
# - 撈取時間:近三個月
# - 需求欄位:暱稱、ID、總儲值金額、近三個月儲值金額、最近購買預測時間、討論區PV、電腦與手機使用比率、最近登入時間
#                                                                       ^^^可以補上佔前幾%
# 條件:
#   (1) 近三個月儲值金額>0 (不要此條件)
#   (2) 討論區PV前80% 
#   (3) 最近登入時間一個月內
# =================================================================================================

# 總儲值金額
CREATE TABLE plsport_playsport._redeem_total engine = myisam
SELECT userid, sum(amount) as redeem_total 
FROM plsport_playsport.pcash_log
WHERE type in (3,4) AND payed = 1
GROUP BY userid;

# 近三個月儲值金額
CREATE TABLE plsport_playsport._redeem_in_three_month engine = myisam
SELECT userid, sum(amount) as redeem_total 
FROM plsport_playsport.pcash_log
WHERE type in (3,4) AND payed = 1
AND date between subdate(now(),90) AND now() 
GROUP BY userid;

# 最近購買預測時間
CREATE TABLE plsport_playsport._buypredict_least_day engine = myisam
SELECT userid, max(date) as buy_least_day, amount
FROM plsport_playsport.pcash_log
WHERE type = 1 AND payed = 1 AND amount > 1
GROUP BY userid;

# 最近登入時間
CREATE TABLE plsport_playsport._last_time_login engine = myisam
SELECT userid, max(signin_time) as signin_time 
FROM plsport_playsport.member_signin_log_archive
GROUP BY userid;

# 討論區PV、電腦與手機使用比率
        CREATE TABLE actionlog._forum engine = myisam
        SELECT userid, uri, time, platform_type as p
        FROM actionlog.action_201410 WHERE userid <> '' AND uri LIKE '%/forum%';

        INSERT IGNORE INTO actionlog._forum
        SELECT userid, uri, time, platform_type as p
        FROM actionlog.action_201411 WHERE userid <> '' AND uri LIKE '%/forum%';

        INSERT IGNORE INTO actionlog._forum
        SELECT userid, uri, time, platform_type as p
        FROM actionlog.action_201412 WHERE userid <> '' AND uri LIKE '%/forum%';

        INSERT IGNORE INTO actionlog._forum
        SELECT userid, uri, time, platform_type as p
        FROM actionlog.action_201501 WHERE userid <> '' AND uri LIKE '%/forum%';

        CREATE TABLE actionlog._forum_0 engine = myisam
        SELECT userid, uri, time, (case when (p<2) then 'pc' else 'mobile' end) as p
        FROM actionlog._forum
        WHERE time between subdate(now(),90) AND now();

        CREATE TABLE actionlog._forum_1 engine = myisam
        SELECT userid, (case when (p='pc') then 1 else 0 end) as pc, 
                       (case when (p='mobile') then 1 else 0 end) as mobile
        FROM actionlog._forum_0;

        CREATE TABLE actionlog._forum_2 engine = myisam
        SELECT userid, sum(pc) as pc, sum(mobile) as mobile 
        FROM actionlog._forum_1
        GROUP BY userid;

        CREATE TABLE actionlog._forum_3 engine = myisam
        SELECT userid, (pc+mobile) as pv, round((pc/(pc+mobile)),2) as pc, round((mobile/(pc+mobile)),2) as mobile
        FROM actionlog._forum_2;

        CREATE TABLE actionlog._forum_4 engine = myisam
        SELECT userid, pv, round((cnt-rank+1)/cnt,2) as pv_percentile, pc, mobile
        FROM (
                SELECT userid, pv, pc, mobile, @curRank := @curRank + 1 AS rank
                FROM actionlog._forum_3, (SELECT @curRank := 0) r
                ORDER BY pv DESC) as dt,
                (SELECT count(distinct userid) as cnt FROM actionlog._forum_3) as ct;

# ............................................................................
# ............................................................................
# 以下才是實際的名單產出過程

        ALTER TABLE plsport_playsport.member convert to character SET utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._forum_4 convert to character SET utf8 collate utf8_general_ci;

CREATE TABLE plsport_playsport._list_1 engine = myisam
SELECT a.userid, b.nickname, a.pv, a.pv_percentile, a.pc, a.mobile 
FROM actionlog._forum_4 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid
WHERE a.pv_percentile >= 0.2;

CREATE TABLE plsport_playsport._list_2 engine = myisam
SELECT c.userid, c.nickname, c.redeem_total, d.redeem_total as redeem_in_three_month, c.pv, c.pv_percentile, c.pc, c.mobile 
FROM (
    SELECT a.userid, a.nickname, b.redeem_total, a.pv, a.pv_percentile, a.pc, a.mobile 
    FROM plsport_playsport._list_1 a LEFT JOIN plsport_playsport._redeem_total b on a.userid = b.userid) as c
    LEFT JOIN plsport_playsport._redeem_in_three_month d on c.userid = d.userid;

CREATE TABLE plsport_playsport._list_3 engine = myisam
SELECT * FROM plsport_playsport._list_2;
# WHERE redeem_in_three_month > 1;

        ALTER TABLE plsport_playsport._list_3 ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._last_time_login ADD INDEX (`userid`);

CREATE TABLE plsport_playsport._list_4 engine = myisam
SELECT a.userid, a.nickname, a.redeem_total, a.redeem_in_three_month, a.pv, a.pv_percentile, a.pc, a.mobile, date(b.signin_time) as signin_time
FROM plsport_playsport._list_3 a LEFT JOIN plsport_playsport._last_time_login b on a.userid = b.userid;

        ALTER TABLE plsport_playsport._list_4 ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._buypredict_least_day ADD INDEX (`userid`);

CREATE TABLE plsport_playsport._list_5 engine = myisam
SELECT a.userid, a.nickname, a.redeem_total, a.redeem_in_three_month, date(b.buy_least_day) as buy_least_day, a.pv, a.pv_percentile, a.pc, a.mobile, a.signin_time
FROM plsport_playsport._list_4 a LEFT JOIN plsport_playsport._buypredict_least_day b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_6 engine = myisam
SELECT * FROM plsport_playsport._list_5
WHERE signin_time between subdate(now(),31) AND now();

# 要跑居住地名單 line:1715

        ALTER TABLE plsport_playsport._list_6 ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._city_info_ok_with_chinese ADD INDEX (`userid`);

CREATE TABLE plsport_playsport._list_7 engine = myisam
SELECT a.userid, a.nickname, a.redeem_total, a.redeem_in_three_month, a.buy_least_day, a.pv, a.pv_percentile, a.pc, a.mobile, a.signin_time, b.city1
FROM plsport_playsport._list_6 a LEFT JOIN plsport_playsport._city_info_ok_with_chinese b on a.userid = b.userid;
# WHERE a.redeem_in_three_month >= 199;


# - 需求欄位:暱稱、ID、總儲值金額、近三個月儲值金額、最近購買預測時間、討論區PV、電腦與手機使用比率、最近登入時間
#                                                                       ^^^可以補上佔前幾%
# 條件:
#   (1) 近三個月儲值金額>0 (不要此條件)
#   (2) 討論區PV前80% 
#   (3) 最近登入時間一個月內

# 2015-01-23 要再新增"預測點擊天數"

        ALTER TABLE prediction.p_recently ADD INDEX (`userid`, `CREATEday`);

CREATE TABLE plsport_playsport._list_7_prediction engine = myisam
SELECT userid, CREATEday, count(userid) as c
FROM prediction.p_recently
GROUP BY userid, CREATEday;


CREATE TABLE plsport_playsport._list_7_prediction_1 engine = myisam
SELECT userid, count(CREATEday) as predict_count
FROM plsport_playsport._list_7_prediction
WHERE CREATEday between subdate(now(),91) AND now()
GROUP BY userid;

CREATE TABLE plsport_playsport._list_7_prediction_2 engine = myisam
SELECT userid, predict_count, round((cnt-rank+1)/cnt,2) as predict_count_percentile
FROM (
        SELECT userid, predict_count, @curRank := @curRank + 1 AS rank
        FROM plsport_playsport._list_7_prediction_1, (SELECT @curRank := 0) r
        ORDER BY predict_count DESC) as dt,
        (SELECT count(distinct userid) as cnt FROM plsport_playsport._list_7_prediction_1) as ct;


        ALTER TABLE plsport_playsport._list_7 ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._list_7_prediction_2 ADD INDEX (`userid`);        


CREATE TABLE plsport_playsport._list_8 engine = myisam
SELECT a.userid, a.nickname, COALESCE(a.redeem_total,0) as redeem_total, COALESCE(a.redeem_in_three_month,0) as redeem_in_three_month, 
       COALESCE(a.buy_least_day, "") as buy_least_day, a.pv, a.pv_percentile, a.pc, a.mobile, a.signin_time, COALESCE(a.city1,'') as city, 
       COALESCE(b.predict_count,0) as predict_count, COALESCE(b.predict_count_percentile,0) as predict_count_percentile
FROM plsport_playsport._list_7 a LEFT JOIN plsport_playsport._list_7_prediction_2 b on a.userid = b.userid;

        update plsport_playsport._list_8 SET nickname = replace(nickname, ' ','');
        update plsport_playsport._list_8 SET nickname = replace(nickname, '　','');
        update plsport_playsport._list_8 SET nickname = replace(nickname, '\\','');
        update plsport_playsport._list_8 SET nickname = replace(nickname, ',','');
        update plsport_playsport._list_8 SET nickname = replace(nickname, ';','');
        update plsport_playsport._list_8 SET nickname = replace(nickname, '\n','');
        update plsport_playsport._list_8 SET nickname = replace(nickname, '\r','');
        update plsport_playsport._list_8 SET nickname = replace(nickname, '\t','');

SELECT 'userid', '暱稱', '總儲值金額', '近三個月儲值金額', '最近購買預測時間','討論區PV','pv為全站前n%','電腦%','手機%','最近登入時間', '居住地',
       '點預測天數', '點預測天數為全站前n%' UNION (
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/mobile_header_improve_mvp_list_2015_01_26.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._list_8);



# =================================================================================================
# 任務: 預測擂台賽名單分組 [新建] (學文) 2015-01-05
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4048&projectId=11
# To eddy
# 
# 討論區接下來會辦一個預測擂台賽的活動
# 1/5會有報名名單出來
# 需要請您幫我們分類
# 
# 目前分類條件：申請帳號未滿一年、申請帳號一年以上
# （可能還會再修改）
# 
# 需求日期：1/6
# =================================================================================================

# 程式都不見了....
# 程式都不見了....
# 程式都不見了....

# 如果要 重跑名單的話, 要重寫_list_1之前的部分

CREATE TABLE plsport_playsport._list_1 engine = myisam
SELECT a.userid, a.nickname, a.join_date, b.post_count_percentile
FROM plsport_playsport._list a LEFT JOIN plsport_playsport._post_count1 b on a.userid = b.postuser;

CREATE TABLE plsport_playsport._list_2 engine = myisam
SELECT a.userid, a.nickname, a.join_date, a.post_count_percentile, b.reply_count_percentile
FROM plsport_playsport._list_1 a LEFT JOIN plsport_playsport._reply_count1 b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_3 engine = myisam
SELECT a.userid, a.nickname, a.join_date, a.post_count_percentile, a.reply_count_percentile, b.LIKE_count_percentile
FROM plsport_playsport._list_2 a LEFT JOIN plsport_playsport._LIKE_count1 b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_4 engine = myisam
SELECT userid, nickname, join_date, post_count_percentile, reply_count_percentile, LIKE_count_percentile 
FROM plsport_playsport._list_3
GROUP BY userid, nickname, join_date, post_count_percentile, reply_count_percentile, LIKE_count_percentile;

CREATE TABLE plsport_playsport._list_5 engine = myisam
SELECT userid, nickname, join_date, (case when (post_count_percentile is null) then 0 else post_count_percentile end) as post,
                                    (case when (reply_count_percentile is null) then 0 else reply_count_percentile end) as reply,
                                    (case when (LIKE_count_percentile is null) then 0 else LIKE_count_percentile end) as LIKE_
FROM plsport_playsport._list_4;


#(1)討論後，我們想要的權重為
#
#    看文:0
#    貼文:7
#    回文:4
#    推文:1
CREATE TABLE plsport_playsport._list_6 engine = myisam
SELECT userid, nickname, join_date, post, reply, LIKE_, round(((post*7 + reply*4 + LIKE_*4)*10),0) as score
FROM plsport_playsport._list_5;

CREATE TABLE plsport_playsport._list_7 engine = myisam
SELECT *
FROM (
    SELECT userid, nickname, join_date, post, reply, LIKE_, score, round((datediff(now(), join_date)/365),2) as y
    FROM plsport_playsport._list_6) as a
ORDER BY a.score DESC, a.y DESC;

update plsport_playsport._list_7 SET nickname  = replace(nickname, ' ','');
update plsport_playsport._list_7 SET nickname  = replace(nickname, ';','');
update plsport_playsport._list_7 SET nickname  = replace(nickname, ',','');
update plsport_playsport._list_7 SET nickname  = replace(nickname, '.','');

# 232筆, 直接貼到文章上即可
# https://docs.google.com/a/playsport.cc/spreadsheets/d/1p13jZzzKSjy2fuoAeXzAFSr77cs-JV3lvleCcHtYJyQ/edit?usp=sharing



# =================================================================================================
# 任務: [201401-J-8] 強化購買後推薦專區 - A/B testing及追蹤報告 [進行中] (阿達) 2015-01-06
# 第四階段優化 (新增國際大小推薦)  
# 
# 測試時間：12/11 ~ 12/31
# 
# 1. 提供測試名單
# 2. 測試報告
#    觀察指標為購買預測營業額、各區塊點擊/購買數 (分成殺手、非殺手)
# 3. 追蹤報告
# 
# =================================================================================================

# 以下是觀察的部分
# 任務: [201401-J-8] 強化購買後推薦專區 - A/B testing及追蹤報告 [進行中]
# http://pm.playsport.cc/index.php/tasksComments?tasksId=2567&projectId=11
# another task
CREATE TABLE plsport_playsport._test engine = myisam
SELECT * FROM plsport_playsport._predict_buyer_with_cons
WHERE date(buy_date) between '2014-12-11' AND '2014-12-15'
AND substr(position,1,3) = 'BRC';

SELECT position, sum(buy_price) as total_revenue 
FROM plsport_playsport._test
GROUP BY position
ORDER BY position;

CREATE TABLE plsport_playsport._test_1 engine = myisam
SELECT * 
FROM actionlog._action_201412
WHERE date(time) between '2014-12-12' AND '2014-12-15'
AND userid <> ''
AND uri LIKE '%rp=%';

CREATE TABLE plsport_playsport._test_2 engine = myisam
SELECT userid, uri, time 
FROM plsport_playsport._test_1;

CREATE TABLE plsport_playsport._test_3 engine = myisam
SELECT * FROM plsport_playsport._test_2
WHERE uri LIKE '%BRC%';

CREATE TABLE plsport_playsport._test_4 engine = myisam
SELECT userid, substr(uri,locate('rp=',uri)+3,length(uri)) as p, uri,
 time
FROM plsport_playsport._test_3;

ALTER TABLE plsport_playsport._test_4 convert to character SET utf8 collate utf8_general_ci;

CREATE TABLE plsport_playsport._test_5 engine = myisam 
SELECT (b.id%20)+1 as g, a.userid, a.p, a.uri, a.time 
FROM plsport_playsport._test_4 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

CREATE TABLE plsport_playsport._test_6 engine = myisam 
SELECT (case when (g>13) then 'a' else 'b' end) as abtest, g, userid, p, uri, time 
FROM plsport_playsport._test_5;

SELECT abtest, p, count(userid) as c 
FROM plsport_playsport._test_6
GROUP BY abtest, p;

SELECT * FROM plsport_playsport._test_6
WHERE abtest = 'a' AND substr(p,6,1) = 'C';

# 以下是分析的部分-------------------------------------------------------

# (1)先把資料捉出來
CREATE TABLE actionlog._visitmember_rp engine = myisam
SELECT userid, uri, time
FROM actionlog.action_201412
WHERE uri LIKE '%rp=%'
AND userid <> ''
AND time between '2014-12-11 15:26:00' AND '2015-01-06 12:00:00';

INSERT IGNORE INTO actionlog._visitmember_rp
SELECT userid, uri, time
FROM actionlog.action_201501
WHERE uri LIKE '%rp=%'
AND userid <> ''
AND time between '2014-12-11 15:26:00' AND '2015-01-06 12:00:00';

# (2)篩出購買後推廌專區的的點擊
CREATE TABLE actionlog._visitmember_rp_1 engine = myisam
SELECT userid, uri, time 
FROM actionlog._visitmember_rp
WHERE uri LIKE '%rp=BRC%';

# (3)捉出BRC的字串
CREATE TABLE actionlog._visitmember_rp_2 engine = myisam
SELECT userid, uri, time, (case when (locate('rp=',uri)>0) then substr(uri,locate('rp=',uri)+3, length(uri)) else '' end) as p
FROM actionlog._visitmember_rp_1;

        SELECT p, count(userid)  
        FROM actionlog._visitmember_rp_2
        GROUP BY p;

        ALTER TABLE actionlog._visitmember_rp_2 convert to character SET utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._visitmember_rp_2 ADD INDEX (`userid`);

# (4)參加實驗的組別是14,15,16,17,18,19,20 (35%的測試者)
CREATE TABLE actionlog._visitmember_rp_3 engine = myisam
SELECT (case when (c.g>13) then 'a' else 'b' end) as abtest, c.g, c.userid, c.time, c.p
FROM (
    SELECT (b.id%20)+1 as g, a.userid, a.time, a.p 
    FROM actionlog._visitmember_rp_2 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid) as c;

        # 沒有排除誤擊的版本
        SELECT abtest, p, count(userid) as c 
        FROM actionlog._visitmember_rp_3
        GROUP BY abtest, p;

CREATE TABLE actionlog._visitmember_rp_4 engine = myisam
SELECT abtest, g, userid, time, p, concat(abtest,'_',p) as c 
FROM actionlog._visitmember_rp_3;

CREATE TABLE actionlog._visitmember_rp_5 engine = myisam
SELECT abtest, g, userid, time, p 
FROM actionlog._visitmember_rp_4
WHERE c not in ('a_BRC1_C','a_BRC2_C','a_BRC3_C','a_BRC4_C'); # 誤擊的情況

        # 有排除誤擊的版本
        SELECT p, count(userid) as pv 
        FROM actionlog._visitmember_rp_5
        GROUP BY p;

#------------------------------------------以上是pv的觀察

# 先篩出透過購買後推廌專區購買的交易
CREATE TABLE plsport_playsport._predict_buyer_with_cons_1 engine = myisam
SELECT buyerid, buy_date, buy_price, position 
FROM plsport_playsport._predict_buyer_with_cons
WHERE buy_date between '2014-12-11 15:26:00' AND '2015-01-06 12:00:00'
AND substr(position,1,3) = 'BRC';

CREATE TABLE plsport_playsport._predict_buyer_with_cons_2 engine = myisam
SELECT (case when (c.g>13) then 'a' else 'b' end) as abtest, c.userid, c.date, c.price, c.p
FROM (
    SELECT (id%20)+1 as g, buyerid as userid, buy_date as date, buy_price as price, position as p 
    FROM plsport_playsport._predict_buyer_with_cons_1 a LEFT JOIN plsport_playsport.member b on a.buyerid = b.userid) as c;

CREATE TABLE plsport_playsport._predict_buyer_with_cons_3 engine = myisam
SELECT *
FROM (
    SELECT abtest, userid, price, p, concat(abtest,'_',p) as c 
    FROM plsport_playsport._predict_buyer_with_cons_2) as a
WHERE a.c not in ('a_BRC1_C','a_BRC2_C','a_BRC3_C','a_BRC4_C');# 誤擊的情況

# 推廌專區購買金額
CREATE TABLE plsport_playsport._predict_buyer_with_cons_4 engine = myisam
SELECT abtest, userid, sum(price) as spent
FROM plsport_playsport._predict_buyer_with_cons_3
GROUP BY abtest, userid;

# 全站購買金額
CREATE TABLE plsport_playsport._predict_buyer_with_cons_all engine = myisam
SELECT a.buyerid, sum(a.buy_price) as total_spent
FROM (
    SELECT buyerid, buy_date, buy_price, position  
    FROM plsport_playsport._predict_buyer_with_cons
    WHERE buy_date between '2014-12-11 15:26:00' AND '2015-01-06 12:00:00') as a
GROUP BY a.buyerid;

# 完成名單
CREATE TABLE plsport_playsport._predict_buyer_with_cons_5 engine = myisam
SELECT a.abtest, a.userid, a.spent, b.total_spent
FROM plsport_playsport._predict_buyer_with_cons_4 a LEFT JOIN plsport_playsport._predict_buyer_with_cons_all b on a.userid = b.buyerid;

# 輸出txt給R
SELECT 'abtest', 'userid', 'spent', 'total_spent' UNION (
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_predict_buyer_with_cons_5.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._predict_buyer_with_cons_5);



# =================================================================================================
# 任務: [201408-A-7]開發回文推功能-發文推ABtesting(介面改變) [新建] (靜怡) 2015-01-07
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4029&projectId=11
# 
# - 統計目前站上發文推使用率(僅限有使用討論區者)
# =================================================================================================

CREATE TABLE actionlog._only_forum engine = myisam
SELECT userid, uri, date(time) as d 
FROM actionlog.action_201412
WHERE time between '2014-12-15 00:00:00' AND '2014-12-31 23:59:59'
AND uri LIKE '%/forum%'
AND userid <> '';

CREATE TABLE actionlog._only_forum_1 engine = myisam
SELECT userid, d, count(uri) as v 
FROM actionlog._only_forum
GROUP BY userid, d;

SELECT d, count(userid) as forum_user 
FROM actionlog._only_forum_1
GROUP BY d;

CREATE TABLE plsport_playsport._forum_LIKE engine = myisam
SELECT subject_id as subjectid, userid, date(CREATE_date) as d 
FROM plsport_playsport.forum_LIKE
WHERE CREATE_date between '2014-12-15 00:00:00' AND '2014-12-31 23:59:59';

CREATE TABLE plsport_playsport._forum_LIKE_1 engine = myisam
SELECT d, userid, count(subjectid) as push 
FROM plsport_playsport._forum_LIKE
GROUP BY d, userid;

SELECT d, count(userid) as push 
FROM plsport_playsport._forum_LIKE_1
GROUP BY d;



# =================================================================================================
# 任務: [201408-A-7]開發回文推功能-發文推ABtesting(介面改變) [新建] (靜怡) 2015-01-12
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4029&projectId=11
# 說明
#  
# 目的：了解新的發文推介面是否吸引使用者
# 目標：發文推點擊率提升
#  
# 內容
#  - 測試時間：12/25~1/8
#  - 設定測試組別
#  - 觀察指標：發文推點擊次數
#  - 報告時間：1/13
#  - 統計目前站上發文推使用率(僅限有使用討論區者)--此為上面的任務, 已完成
# =================================================================================================

CREATE TABLE plsport_playsport._forum_LIKE engine = myisam
SELECT * 
FROM plsport_playsport.forum_LIKE
WHERE CREATE_date between '2014-12-25 10:00:00' AND '2015-01-20 00:00:00';

CREATE TABLE plsport_playsport._forum_LIKE1 engine = myisam
SELECT userid, count(subject_id) as LIKE_count 
FROM plsport_playsport._forum_LIKE
GROUP BY userid;

CREATE TABLE plsport_playsport._forum_LIKE2 engine = myisam
SELECT c.g, (case when (c.g>10) then 'a' else 'b' end) as abtest, c.userid, c.LIKE_count
FROM (
    SELECT (b.id%20)+1 as g, a.userid, a.LIKE_count
    FROM plsport_playsport._forum_LIKE1 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid) as c;


SELECT 'g', 'abtest', 'userid', 'LIKE_count' UNION (
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_forum_LIKE2.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._forum_LIKE2);



# =================================================================================================
# 任務: [201408-A-10]開發回文推功能-使用狀況報告 [新建] (靜怡) 2015-01-29
# 目的:了解使用者對回文推的使用狀況
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4192&projectId=11
# 內容
# - 觀察時間:1/15~1/29
# - 觀察指標
#     使用率達16%以上(有看討論區的使用者)
#     滿意度問卷4分以上
#     回文數
# 
# - 報告時間:1/30 
# =================================================================================================

# 先匯入 (1)forum_reply_LIKE 回文推
#        (2)forum_LIKE 發文推

# (1)誰看過討論區
CREATE TABLE actionlog._who_visit_forum engine = myisam
SELECT userid, uri, date(time) as d 
FROM actionlog.action_201501
WHERE time between '2015-01-15 14:00:00' AND '2015-01-28 23:59:59'
AND uri LIKE '%/forum%'
AND userid <> '';

# (2)發文推
CREATE TABLE plsport_playsport._forum_LIKE engine = myisam
SELECT subject_id as subjectid, userid, date(CREATE_date) as d 
FROM plsport_playsport.forum_LIKE
WHERE CREATE_date between '2015-01-15 14:00:00' AND '2015-01-28 23:59:59';

# (3)回文推
CREATE TABLE plsport_playsport._forum_reply_LIKE engine = myisam
SELECT subjectid, userid, date(CREATE_date) as d 
FROM plsport_playsport.forum_reply_LIKE
WHERE CREATE_date between '2015-01-15 14:00:00' AND '2015-01-28 23:59:59';


CREATE TABLE actionlog._who_visit_forum_1 engine = myisam
SELECT d, userid, count(uri) as c 
FROM actionlog._who_visit_forum
GROUP BY d, userid;

CREATE TABLE actionlog._who_visit_forum_2 engine = myisam
SELECT d, count(userid) as forum_visit_user_count 
FROM actionlog._who_visit_forum_1
GROUP BY d;

CREATE TABLE plsport_playsport._forum_LIKE_1 engine = myisam
SELECT a.d, count(a.userid) as post_user_count 
FROM (
    SELECT userid, d, count(subjectid) as post_LIKE_count 
    FROM plsport_playsport._forum_LIKE
    GROUP BY userid, d) as a
GROUP BY a.d;

CREATE TABLE plsport_playsport._forum_reply_LIKE_1 engine = myisam
SELECT a.d, count(a.userid) as reply_user_count
FROM (
    SELECT d, userid, count(subjectid) as c 
    FROM plsport_playsport._forum_reply_LIKE
    GROUP BY d, userid) as a
GROUP BY a.d;


# 分析發文者、回文者、觀看者的問卷填寫結果
# 
# 問卷結果：http://www.playsport.cc/questionnaire.php?question=replyLIKE&action=statistics
# 詳細結果下載：http://www.playsport.cc/questionnaire.php?question=replyLIKE&action=getCsv

# 匯入 (1) forum
#      (2) forumcontent
#      (3) member

CREATE TABLE actionlog._forum_pv engine = myisam
SELECT userid, count(uri) as pv 
FROM actionlog._who_visit_forum
GROUP BY userid;

CREATE TABLE plsport_playsport._user_post engine = myisam
SELECT postuser as userid, count(subjectid) as post_count
FROM plsport_playsport.forum
WHERE posttime between '2015-01-15 14:00:00' AND '2015-01-28 23:59:59'
GROUP BY postuser;

CREATE TABLE plsport_playsport._user_reply engine = myisam
SELECT userid, count(subjectid) as reply_count
FROM plsport_playsport.forumcontent
WHERE postdate between '2015-01-15 14:00:00' AND '2015-01-28 23:59:59'
GROUP BY userid;

CREATE TABLE actionlog._forum_pv_1 engine = myisam
SELECT userid, pv, round((cnt-rank+1)/cnt,2) as pv_p
FROM (SELECT userid, pv, @curRank := @curRank + 1 AS rank
      FROM actionlog._forum_pv, (SELECT @curRank := 0) r
      ORDER BY pv DESC) as dt,
     (SELECT count(distinct userid) as cnt FROM actionlog._forum_pv) as ct;

CREATE TABLE plsport_playsport._user_post_1 engine = myisam
SELECT userid, post_count, round((cnt-rank+1)/cnt,2) as post_p
FROM (SELECT userid, post_count, @curRank := @curRank + 1 AS rank
      FROM plsport_playsport._user_post, (SELECT @curRank := 0) r
      ORDER BY post_count DESC) as dt,
     (SELECT count(distinct userid) as cnt FROM plsport_playsport._user_post) as ct;

CREATE TABLE plsport_playsport._user_reply_1 engine = myisam
SELECT userid, reply_count, round((cnt-rank+1)/cnt,2) as reply_p
FROM (SELECT userid, reply_count, @curRank := @curRank + 1 AS rank
      FROM plsport_playsport._user_reply, (SELECT @curRank := 0) r
      ORDER BY reply_count DESC) as dt,
     (SELECT count(distinct userid) as cnt FROM plsport_playsport._user_reply) as ct;

        ALTER TABLE actionlog._forum_pv_1 convert to character SET utf8 collate utf8_general_ci;
        ALTER TABLE plsport_playsport._user_post_1 convert to character SET utf8 collate utf8_general_ci;
        ALTER TABLE plsport_playsport._user_reply_1 convert to character SET utf8 collate utf8_general_ci;

        ALTER TABLE actionlog._forum_pv_1 ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._user_post_1  ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._user_reply_1 ADD INDEX (`userid`);

CREATE TABLE plsport_playsport._list_1 engine = myisam 
SELECT a.userid, a.nickname, b.pv, b.pv_p
FROM plsport_playsport.member a LEFT JOIN actionlog._forum_pv_1 b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_2 engine = myisam 
SELECT a.userid, a.nickname, a.pv, a.pv_p, b.post_count, b.post_p
FROM plsport_playsport._list_1 a LEFT JOIN plsport_playsport._user_post_1 b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_3 engine = myisam 
SELECT a.userid, a.nickname, a.pv, a.pv_p, a.post_count, a.post_p, b.reply_count, b.reply_p
FROM plsport_playsport._list_2 a LEFT JOIN plsport_playsport._user_reply_1 b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_4 engine = myisam 
SELECT userid, nickname, pv_p, post_p, reply_p
FROM plsport_playsport._list_3
WHERE pv is not null
ORDER BY pv_p DESC;

CREATE TABLE plsport_playsport._list_5 engine = myisam
SELECT a.userid, a.nickname, a.pv_p, a.post_p, a.reply_p, (a.post_lv+a.reply_lv) as act, (case when (a.pv_p>0.79) then 1 else 0 end) as see
FROM (
    SELECT userid, nickname, pv_p, post_p, reply_p, (case when (post_p>0.79) then 1 else 0 end) as post_lv, 
                                                    (case when (reply_p>0.79) then 1 else 0 end) as reply_lv
    FROM plsport_playsport._list_4) as a;

CREATE TABLE plsport_playsport._list_6 engine = myisam
SELECT a.userid, a.nickname, a.act, a.see, concat(a.act,a.see) as p
FROM (
    SELECT userid, nickname, (case when (act>0) then 1 else 0 end) as act, see
    FROM plsport_playsport._list_5) as a;

# 首先我先將討論區的使用者分為4種類型, 簡稱ABCD
# 
#     D: 通常在討論常發回文(前20%)的人, 也常看文(前20%)的人, 稱重度使用者
#     C: 常在討論區看文(前20%), 但較少互動的人(後80%), 稱潛水者
#     B: 常在討論區互動(前20%), 但又很少在看文, 這群人行為較特別, 人數只佔2%
#     A: 不常發回文(後80%)且不常看文(後80%), 稱一般討論區使用者
    
CREATE TABLE plsport_playsport._list_7 engine = myisam
SELECT userid, nickname, (case when (p=11) then 'vip' # D
                               when (p=01) then 'see' # C
                               when (p=10) then 'say' # B
                               when (p=00) then 'nor' else 'XXX' end) as stat # A
FROM plsport_playsport._list_6;

CREATE TABLE plsport_playsport._list_8 engine = myisam
SELECT a.userid, a.score, b.stat, a.recommend
FROM plsport_playsport.questionnaire_replyLIKE_answer a LEFT JOIN plsport_playsport._list_7 b on a.userid = b.userid
WHERE a.userid <> '';

SELECT stat, avg(score) 
FROM plsport_playsport._list_8
GROUP BY stat;

SELECT stat, score, count(userid) as c 
FROM plsport_playsport._list_8
GROUP BY stat, score;



# =================================================================================================
# 任務: [201408-A-11]開發回文推功能-第二次發文推樣式ABtesting [新建]
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4258&projectId=11
# 說明
# 目的：了解新的發文推介面是否吸引使用者
# 
# 內容
# - 測試時間：待補
# - 設定測試組別
# - 觀察指標：1.發文推點擊次數、2.發文推比
# - 報告時間：請於2/24先確認狀況，再評估是否要繼續執行
# =================================================================================================

# 要先匯入events(linode上)
CREATE TABLE plsport_playsport._events engine = myisam
SELECT * FROM plsport_playsport.events
WHERE name LIKE '%pushit_bottom%'
AND time between '2015-02-06 14:45:00' AND now()
ORDER BY time DESC;

        ALTER TABLE plsport_playsport._events convert to character SET utf8 collate utf8_general_ci;
        ALTER TABLE plsport_playsport._events ADD INDEX (`userid`);

CREATE TABLE plsport_playsport._events_1 engine = myisam
SELECT c.userid, c.g, (case when (c.g < 11) then 'a' else 'b' end) as abtest, c.name, c.time
FROM (
    SELECT a.userid, (b.id%20)+1 as g, a.name, a.time 
    FROM plsport_playsport._events a LEFT JOIN plsport_playsport.member b on a.userid = b.userid) as c;

SELECT abtest, name, count(userid) as c 
FROM plsport_playsport._events_1
GROUP BY abtest, name;

# a pushit_bottom_a 14688
# a pushit_bottom_b 4
# b pushit_bottom_a 24
# b pushit_bottom_b 15242

CREATE TABLE plsport_playsport._events_2 engine = myisam
SELECT a.userid, a.g, a.abtest, a.name, a.time
FROM (
    SELECT userid, g, abtest, name, time, concat(abtest,'_',name) as c 
    FROM plsport_playsport._events_1) as a
WHERE a.c in ('a_pushit_bottom_a','b_pushit_bottom_b');

CREATE TABLE plsport_playsport._push_count engine = myisam
SELECT abtest, userid, count(name) as push_c 
FROM plsport_playsport._events_2
WHERE userid <> ''
GROUP BY userid;

SELECT abtest, count(userid) as c 
FROM plsport_playsport._push_count
GROUP BY abtest;

# a 1154
# b 1145

# 輸出給R使用
SELECT 'abtest', 'userid', 'push_c' UNION (
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_push_count.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._push_count);

CREATE TABLE plsport_playsport._forum_see_count engine = myisam
SELECT userid, count(uri) as c
FROM actionlog._forum_1
WHERE time between '2015-02-06 14:45:00' AND now()
GROUP BY userid;

        ALTER TABLE plsport_playsport._forum_see_count convert to character SET utf8 collate utf8_general_ci;
        ALTER TABLE plsport_playsport._forum_see_count ADD INDEX (`userid`);

CREATE TABLE plsport_playsport._forum_see_count_1 engine = myisam
SELECT c.userid, c.g, (case when (c.g<11) then 'a' else 'b' end) as abtest, c.c
FROM (
    SELECT a.userid, (b.id%20)+1 as g, a.c
    FROM plsport_playsport._forum_see_count a LEFT JOIN plsport_playsport.member b on a.userid = b.userid) as c;

SELECT abtest, count(userid) as c 
FROM plsport_playsport._forum_see_count_1
WHERE c > 5
GROUP BY abtest;

# a 5048
# b 4990

# =================================================================================================
# 任務: [201408-A-15]開發回文推功能-第三次發文推樣式ABtesting [新建] (靜怡) 2015-04-28
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4436&projectId=11
# 目的：找出發文推降低的原因
# 內容
# 
# - 測試時間：3/25~4/25
# - 提供測試組別
# - 觀察指標：1.發文推點擊次數、2.發文推比
# - 另提供手機發文推點擊狀況
# - 報告時間：4/27
# =================================================================================================

# 要先匯入events(linode上)

CREATE TABLE plsport_playsport._events engine = myisam
SELECT * FROM plsport_playsport.events
WHERE name LIKE '%pushit_bottom%'
AND time between '2015-03-25 13:36:00' AND now() # 2015-03-25 13:36上線
ORDER BY time DESC;

        ALTER TABLE plsport_playsport._events convert to character SET utf8 collate utf8_general_ci;
        ALTER TABLE plsport_playsport._events ADD INDEX (`userid`);

CREATE TABLE plsport_playsport._events_1 engine = myisam
SELECT c.userid, c.g, (case when (c.g < 11) then 'a' else 'b' end) as abtest, c.name, c.time # a為測試組
FROM (
    SELECT a.userid, (b.id%20)+1 as g, a.name, a.time 
    FROM plsport_playsport._events a LEFT JOIN plsport_playsport.member b on a.userid = b.userid) as c;

SELECT abtest, name, count(userid) as c 
FROM plsport_playsport._events_1
GROUP BY abtest, name;

# a	pushit_bottom_a	59881
# a	pushit_bottom_b	2
# b	pushit_bottom_a	5
# b	pushit_bottom_b	72986

CREATE TABLE plsport_playsport._events_3 engine = myisam
select a.abtest, a.userid, count(a.userid) as click
from (
    SELECT abtest, userid, substr(name,length(name),length(name)+1) as p
    FROM plsport_playsport._events_1) as a
where a.abtest = a.p
group by a.abtest, a.userid;


SELECT abtest, count(userid) as user_count 
FROM plsport_playsport._events_3
group by abtest;


SELECT 'abtest', 'userid', 'click' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_events_3.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._events_3);


create table plsport_playsport._events_1_for_d engine = myisam
SELECT userid, g, abtest, name, substr(time,1,16) as t
FROM plsport_playsport._events_1;

create table actionlog._action_log_forumdetail_for_d engine = myisam
SELECT userid, substr(time,1,16) as t, (case when (platform_type<2) then 1 else 2 end) as p
FROM actionlog._action_log_forumdetail;

        ALTER TABLE actionlog._action_log_forumdetail_for_d ADD INDEX (`t`,`userid`);
        ALTER TABLE actionlog._action_log_forumdetail_for_d convert to character SET utf8 collate utf8_general_ci;

create table actionlog._action_log_forumdetail_for_d1 engine = myisam
SELECT userid, t, p 
FROM actionlog._action_log_forumdetail_for_d
group by userid, t, p;

        ALTER TABLE actionlog._action_log_forumdetail_for_d1 ADD INDEX (`t`,`userid`);
        ALTER TABLE actionlog._action_log_forumdetail_for_d1 convert to character SET utf8 collate utf8_general_ci;
        ALTER TABLE plsport_playsport._events_1_for_d ADD INDEX (`t`,`userid`);
        ALTER TABLE plsport_playsport._events_1_for_d convert to character SET utf8 collate utf8_general_ci;

create table plsport_playsport._events_2_for_d engine = myisam
SELECT a.userid, a.g, a.abtest, a.name, a.t, b.p
FROM plsport_playsport._events_1_for_d a left join actionlog._action_log_forumdetail_for_d1 b on a.userid = b.userid and a.t = b.t
where b.p is not null;

# a	2515
# b	2623

create table actionlog._action_log_forumdetail engine = myisam
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201503
where uri like '%forumdetail.php%' and userid <> ''
and time between '2015-03-25 13:36:00' and now();

insert ignore into actionlog._action_log_forumdetail
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201504
where uri like '%forumdetail.php%' and userid <> ''
and time between '2015-03-25 13:36:00' and now();

create table actionlog._forumdetail engine = myisam
SELECT userid, count(uri) as v 
FROM actionlog._action_log_forumdetail
group by userid;

        ALTER TABLE actionlog._forumdetail ADD INDEX (`userid`);
        ALTER TABLE actionlog._forumdetail convert to character SET utf8 collate utf8_general_ci;

create table actionlog._forumdetail_user_count engine = myisam
SELECT (case when ((b.id%20)+1<11) then 'a' else 'b' end) as abtest, a.userid, a.v 
FROM actionlog._forumdetail a left join plsport_playsport.member b on a.userid = b.userid;

SELECT abtest, count(userid) as c 
FROM actionlog._forumdetail_user_count
group by abtest;

# a	7973 > 2515
# b	8015 > 2623




# =================================================================================================
# 新增專案: 行銷企劃 - 1月nba分析王活動表格 [任務](學文) 2015-01-07
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4108&projectId=11
# =================================================================================================

use wa;

DROP TABLE IF EXISTS wa._wa_forum;
DROP TABLE IF EXISTS wa._wa_score;
DROP TABLE IF EXISTS wa._wa_forum_1;
DROP TABLE IF EXISTS wa._wa_forum_ok;

CREATE TABLE wa._wa_forum engine = myisam
SELECT subjectid, gametype, subject, postuser, posttime
FROM plsport_playsport.forum
WHERE date(posttime) = '2015-01-22'
AND gametype = 1
AND allianceid = 3
AND isdelete = 0;

CREATE TABLE wa._wa_score engine = myisam
SELECT subjectid, count(userid) as user_count, sum(score) as total_score
FROM plsport_playsport.forum_analysis_score
WHERE datetime between '2015-01-22 00:00:00' AND '2015-01-23 13:00:00'
GROUP BY subjectid;

# today當天
CREATE TABLE wa._wa_forum_1 engine = myisam
SELECT c.subjectid, c.subject, c.postuser, d.nickname, c.posttime, c.user_count, c.total_score 
FROM (
    SELECT a.subjectid, a.subject, a.postuser, a.posttime, b.user_count, b.total_score 
    FROM wa._wa_forum a LEFT JOIN wa._wa_score b on a.subjectid = b.subjectid) as c 
    LEFT JOIN plsport_playsport.member as d on c.postuser = d.userid
ORDER BY c.user_count DESC;

        # 第一天
        CREATE TABLE wa._wa_forum_2 engine = myisam
        SELECT * FROM wa._wa_forum_1;
        
        CREATE TABLE wa._forumbackup_20150122
        SELECT * FROM wa._wa_forum_1;

        # 之後的每一天
        INSERT IGNORE INTO wa._wa_forum_2
        SELECT * FROM wa._wa_forum_1;

        update wa._wa_forum_2 SET subject = replace(subject, ' ','');
        update wa._wa_forum_2 SET subject = replace(subject, '　','');
        update wa._wa_forum_2 SET subject = replace(subject, '\\','');
        update wa._wa_forum_2 SET subject = replace(subject, ',','');
        update wa._wa_forum_2 SET subject = replace(subject, ';','');
        update wa._wa_forum_2 SET subject = replace(subject, '\n','');
        update wa._wa_forum_2 SET subject = replace(subject, '\r','');
        update wa._wa_forum_2 SET subject = replace(subject, '\t','');

        SELECT 'subjectid', 'subject', 'userid', 'nickname', '貼文時間', '評分人數', '得分' UNION (
        SELECT *
        INTO outfile 'C:/Users/1-7_ASUS/Dropbox/playsport/2015-01-22.csv'
        fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
        FROM wa._wa_forum_2);

# all_day
CREATE TABLE wa._wa_forum_ok engine = myisam
SELECT *
FROM (
    SELECT  a.postuser, a.nickname, a.post_count, a.user_count, a.total_score, (a.total_score/a.user_count) as avg_score
    FROM (
        SELECT postuser, nickname, count(subjectid) as post_count, sum(user_count) as user_count, sum(total_score) as total_score
        FROM wa._wa_forum_2
        GROUP BY postuser) as a) as b
ORDER BY b.user_count DESC;

        SELECT 'postuser', 'nickname', '累計文章篇數', '累計評分人數', '累計總分', '平均分數' UNION (
        SELECT *
        INTO outfile 'C:/Users/1-7_ASUS/Dropbox/playsport/2015-01-22_result.csv'
        fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
        FROM wa._wa_forum_ok);



# =================================================================================================
# 任務: [201412-E-3] NBA即時比分新增團隊數據 - MVP測試名單 [新建] (阿達) 2015-01-09
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4095&projectId=11
# 提供此任務 MVP測試名單
# 負責人：Eddy
# 時間：1/12(一) 
# 內容
# 1. MVP測試名單
# 時間：近兩個月
# 
# 條件：
#   a. NBA即時比分PV前50%
#   b. 問卷第四題回答需要或非常需要
# 欄位：
#   a. 帳號
#   b. 暱稱
#   c. 近兩個月NBA即時比分pv及全站佔比
#   d. 近兩個月點選NBA隔日的次數
#   e. 問卷第四題答案
#   f. 近兩個月點選對戰資訊/球隊資訊總pv(games_data.php)
# =================================================================================================

CREATE TABLE actionlog._livescore engine = myisam
SELECT userid, uri, time FROM actionlog.action_201411 WHERE uri LIKE '%/livescore%' AND userid <> '';
INSERT IGNORE INTO actionlog._livescore
SELECT userid, uri, time FROM actionlog.action_201412 WHERE uri LIKE '%/livescore%' AND userid <> '';
INSERT IGNORE INTO actionlog._livescore
SELECT userid, uri, time FROM actionlog.action_201501 WHERE uri LIKE '%/livescore%' AND userid <> '';

CREATE TABLE actionlog._gamedata engine = myisam
SELECT userid, uri, time FROM actionlog.action_201411 WHERE uri LIKE '%/games_data.php%' AND userid <> '';
INSERT IGNORE INTO actionlog._gamedata
SELECT userid, uri, time FROM actionlog.action_201412 WHERE uri LIKE '%/games_data.php%' AND userid <> '';
INSERT IGNORE INTO actionlog._gamedata
SELECT userid, uri, time FROM actionlog.action_201501 WHERE uri LIKE '%/games_data.php%' AND userid <> '';

CREATE TABLE actionlog._livescore_1 engine = myisam
SELECT * 
FROM actionlog._livescore
WHERE time between subdate(now(),65) AND now();

CREATE TABLE actionlog._gamedata_1 engine = myisam
SELECT * 
FROM actionlog._gamedata
WHERE time between subdate(now(),65) AND now();

CREATE TABLE actionlog._livescore_2 engine = myisam
SELECT a.userid, a.uri, a.time, (case when (locate('&',a.t)=0) then a.t else substr(a.t,1,locate('&',a.t)-1) end) as p
FROM (
    SELECT userid, uri, time, (case when (locate('aid=',uri)=0) then 3 else substr(uri, locate('aid=',uri)+4, length(uri)) end) as t
    FROM actionlog._livescore_1) as a;

CREATE TABLE actionlog._livescore_3 engine = myisam
SELECT * 
FROM actionlog._livescore_2
WHERE length(p) in (1,2)
AND p = 3;

CREATE TABLE actionlog._livescore_4 engine = myisam
SELECT userid, count(uri) as livesocre_pv
FROM actionlog._livescore_3
GROUP BY userid;

        CREATE TABLE actionlog._livescore_list engine = myisam
        SELECT userid, livesocre_pv, round((cnt-rank+1)/cnt,2) as livescore_percentile
        FROM (SELECT userid, livesocre_pv, @curRank := @curRank + 1 AS rank
              FROM actionlog._livescore_4, (SELECT @curRank := 0) r
              ORDER BY livesocre_pv DESC) as dt,
             (SELECT count(distinct userid) as cnt FROM actionlog._livescore_4) as ct;

CREATE TABLE actionlog._gamedata_2 engine = myisam
SELECT userid, count(uri) as gamedata_pv 
FROM actionlog._gamedata_1
GROUP BY userid;

        CREATE TABLE actionlog._gamedata_list engine = myisam
        SELECT userid, gamedata_pv, round((cnt-rank+1)/cnt,2) as gamedata_percentile
        FROM (SELECT userid, gamedata_pv, @curRank := @curRank + 1 AS rank
              FROM actionlog._gamedata_2, (SELECT @curRank := 0) r
              ORDER BY gamedata_pv DESC) as dt,
             (SELECT count(distinct userid) as cnt FROM actionlog._livescore_4) as ct;

CREATE TABLE actionlog._livescore_nextday_1 engine = myisam
SELECT a.userid, a.uri, a.time, a.p, substr(a.c,1,8) as nextday
FROM (
    SELECT userid, uri, time, p, (case when (locate('gamedate=', uri)=0) then "" else substr(uri,locate('gamedate=', uri)+9,length(uri)) end) as c
    FROM actionlog._livescore_3) as a;

CREATE TABLE actionlog._livescore_nextday_2 engine = myisam
SELECT userid, uri, date(time) as today, str_to_date(nextday, '%Y%m%d') as nextday, p, datediff(str_to_date(nextday, '%Y%m%d'), date(time)) as s
FROM actionlog._livescore_nextday_1
WHERE nextday <> '';
        
        # 看看大家都是點那幾天
        SELECT s, count(userid) 
        FROM actionlog._livescore_nextday_2
        GROUP BY s;

#抽出點選明天的人
CREATE TABLE actionlog._livescore_nextday_3 engine = myisam
SELECT * FROM actionlog._livescore_nextday_2
WHERE s = 1;

CREATE TABLE actionlog._livescore_nextday_4 engine = myisam
SELECT userid, count(uri) as nextday_pv 
FROM actionlog._livescore_nextday_3
GROUP BY userid;

        CREATE TABLE actionlog._livescore_nextday_list engine = myisam
        SELECT userid, nextday_pv, round((cnt-rank+1)/cnt,2) as nextday_pv_percentile
        FROM (SELECT userid, nextday_pv, @curRank := @curRank + 1 AS rank
              FROM actionlog._livescore_nextday_4, (SELECT @curRank := 0) r
              ORDER BY nextday_pv DESC) as dt,
             (SELECT count(distinct userid) as cnt FROM actionlog._livescore_nextday_4) as ct;


        ALTER TABLE actionlog._livescore_list convert to character SET utf8 collate utf8_general_ci;

CREATE TABLE actionlog._list_1 engine = myisam
SELECT a.userid, b.nickname, a.livesocre_pv, a.livescore_percentile 
FROM actionlog._livescore_list a LEFT JOIN plsport_playsport.member b on a.userid = b.userid
WHERE livescore_percentile > 0.49; # NBA即時比分PV前50%

        ALTER TABLE actionlog._livescore_nextday_list convert to character SET utf8 collate utf8_general_ci;

CREATE TABLE actionlog._list_2 engine = myisam
SELECT a.userid, a.nickname, a.livesocre_pv, a.livescore_percentile, b.nextday_pv, b.nextday_pv_percentile
FROM actionlog._list_1 a LEFT JOIN actionlog._livescore_nextday_list b on a.userid = b.userid;

        ALTER TABLE actionlog._gamedata_list convert to character SET utf8 collate utf8_general_ci;

CREATE TABLE actionlog._list_3 engine = myisam
SELECT a.userid, a.nickname, a.livesocre_pv, a.livescore_percentile, a.nextday_pv, a.nextday_pv_percentile, b.gamedata_pv, b.gamedata_percentile
FROM actionlog._list_2 a LEFT JOIN actionlog._gamedata_list b on a.userid = b.userid;

        # 最近一次的登入時間
        CREATE TABLE plsport_playsport._last_login_time engine = myisam
        SELECT userid, max(signin_time) as last_login
        FROM plsport_playsport.member_signin_log_archive
        GROUP BY userid;

        CREATE TABLE plsport_playsport._question_list engine = myisam
        SELECT userid, question04
        FROM plsport_playsport.questionnaire_livescorenbaviewimprovement_answer
        WHERE question04 in (1,2,3,4,5); # 問卷第四題回答需要或非常需要

        ALTER TABLE plsport_playsport._last_login_time convert to character SET utf8 collate utf8_general_ci;
        ALTER TABLE plsport_playsport._question_list convert to character SET utf8 collate utf8_general_ci;


CREATE TABLE actionlog._list_4 engine = myisam
SELECT a.userid, a.nickname, a.livesocre_pv, a.livescore_percentile, a.nextday_pv, a.nextday_pv_percentile, a.gamedata_pv, a.gamedata_percentile,
       b.question04
FROM actionlog._list_3 a LEFT JOIN plsport_playsport._question_list b on a.userid = b.userid;

        ALTER TABLE actionlog._list_4 ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._last_login_time ADD INDEX (`userid`);

CREATE TABLE actionlog._list_5 engine = myisam
SELECT a.userid, a.nickname, a.livesocre_pv, a.livescore_percentile, a.nextday_pv, a.nextday_pv_percentile, a.gamedata_pv, a.gamedata_percentile,
       a.question04, date(b.last_login) as last_login
FROM actionlog._list_4 a LEFT JOIN plsport_playsport._last_login_time b on a.userid = b.userid;

SELECT 'userid', 'nickname', '即時比分pv', '佔全站前n%', '點擊隔天pv', '佔全站前n%', '看數據pv', '佔全站前n%', '問卷第四題答案', '最後登入時間' UNION (
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_list_5.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._list_5);



# =================================================================================================
# 任務: [201404-C-9]優化APP版標-ANDroid即時比分ABtesting分組工程 [等候確認]
# http://pm.playsport.cc/index.php/tasksComments?tasksId=3892&projectId=1
# 12/17星期三要觀察
# 任務: [201404-C-11]優化APP版標-ANDroid即時比分ABtesting [新建] (靜怡) 2015-01-16
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4041&projectId=11
# 
# 說明
#  
# 目的:了解使用者喜愛哪組版標
# 
# - 測試方法
#  
#     同時進行二種版標測試
#     由20組分成二大組
#     依據點擊次數進行評估
#     進行二周
# 
# - 分組:EDDY提供組別
# - 測試時間:1/15~1/31
# - 觀察指標:1.兩組點擊狀況2.各版標類型點擊狀況
# - 報告時間:2/3
# - 目前APP版本:2.2.4(含)
# =================================================================================================

# 要先匯入app_actioin_log

CREATE TABLE plsport_playsport._app_action_log engine=myisam 
SELECT * FROM
    plsport_playsport.app_action_log
WHERE
    app = 1 AND os = 1    #app=1即時比分, os=1是ANDriod 
    AND appversion in ( '2.2.4','2.2.5','2.2.6','2.2.7',
                        '2.2.8','2.2.9','2.3.0','2.3.1','2.3.2','2.3.3','2.3.4'); # ver2.2.4~2.3.1都是用新的log
                                                                  # 2.3.2 新增記錄坐標功能 (update:2015/1/27)

# 任務: [201404-C-10]優化APP版標-ANDroid即時比分ABtesting分組觀察 [新建]
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4007&projectId=11

        ALTER TABLE plsport_playsport._app_action_log ADD INDEX (`userid`,`datetime`,`deviceid`,`devicemodel`);

# 排除掉重覆送出的log, 小呆已修正此問題, 但之後撈app_action_log都還是要執行一下此段SQL (花了大概13分)
CREATE TABLE plsport_playsport._app_action_log_0 engine = myisam
SELECT appversion, userid, action, remark, datetime, deviceid, abtestgroup, devicemodel, deviceosversion 
FROM plsport_playsport._app_action_log
GROUP BY appversion, userid, action, remark, datetime, deviceid, devicemodel, deviceosversion;

# 查詢
SELECT a.abtestgroup, count(deviceid) as a
FROM (
    SELECT deviceid, abtestgroup, count(action) as c 
    FROM plsport_playsport._app_action_log_0
    WHERE abtestgroup <> 0 # 除了0不用看, 看1~20組
    GROUP BY deviceid, abtestgroup) as a
GROUP BY a.abtestgroup;

CREATE TABLE plsport_playsport._app_action_log_1 engine = myisam
SELECT * FROM plsport_playsport._app_action_log_0
WHERE action = 'clicktitle'
AND datetime between '2015-01-15 09:30:00' AND now() # ab testing開始時間
ORDER BY datetime DESC;



# 晨暐的檢察SQL

SELECT appVersion, COUNT(*) AS C 
FROM app_action_log 
WHERE remark = 'Click_Title_Default' AND abtestGroup <= 10 
AND datetime between '2015-01-15 09:30:00' AND now()
GROUP BY appVersion;

SELECT appVersion, COUNT(*) AS C 
FROM app_action_log 
WHERE remark = 'Click_Title_Default' AND abtestGroup > 10 
AND datetime between '2015-01-15 09:30:00' AND now()
GROUP BY appVersion;


SELECT * 
FROM app_action_log 
WHERE remark = 'Click_Title_Default' AND abtestGroup > 10 
AND appVersion in ('2.3.0','2.3.1')
ORDER BY datetime DESC;



# ------以下開始分析-------(2015-01-30)靜怡------------------------------------------------------------------
# 任務: [201404-C-11]優化APP版標-ANDroid即時比分ABtesting [新建]
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4041&projectId=11

CREATE TABLE plsport_playsport._app_action_log engine=myisam 
SELECT * FROM
    plsport_playsport.app_action_log
WHERE
    app = 1 AND os = 1    #app=1即時比分, os=1是ANDriod 
    AND appversion in ( '2.2.4','2.2.5','2.2.6','2.2.7',
                        '2.2.8','2.2.9','2.3.0','2.3.1','2.3.2','2.3.3','2.3.4','2.3.4','2.3.5','2.3.6','2.3.7'); # ver2.2.4~2.3.1都是用新的log
                                                                  # 2.3.2 新增記錄坐標功能 (update:2015/1/27)

CREATE TABLE plsport_playsport._app_action_log_1 engine=myisam # 撈出點擊板標記錄
SELECT * 
FROM plsport_playsport._app_action_log
WHERE action = 'clickTitle'
ORDER BY datetime DESC;

        ALTER TABLE plsport_playsport._app_action_log_1 ADD INDEX (`userid`,`datetime`,`deviceid`,`devicemodel`);

        # 排除掉重覆送出的log, 小呆已修正此問題, 但之後撈app_action_log都還是要執行一下此段SQL
        CREATE TABLE plsport_playsport._app_action_log_2 engine = myisam
        SELECT appversion, userid, action, remark, datetime, deviceid, abtestgroup, devicemodel, deviceosversion 
        FROM plsport_playsport._app_action_log_1
        GROUP BY appversion, userid, action, remark, datetime, deviceid, devicemodel, deviceosversion;

        CREATE TABLE plsport_playsport._app_action_log_2 engine = myisam
        SELECT appversion, userid, action, remark, datetime, deviceid, abtestgroup, devicemodel, deviceosversion  
        FROM plsport_playsport._app_action_log_1
        WHERE datetime between '2015-02-16 16:58:00' AND now();

CREATE TABLE plsport_playsport._app_action_log_3 engine = myisam
SELECT action, remark, datetime, deviceid, abtestgroup, (case when (abtestgroup<11) then 'a' else 'b' end) as g, devicemodel
FROM plsport_playsport._app_action_log_2
WHERE datetime between '2015-02-16 16:58:00' AND now(); # ABtesting已於1/15 9:30上線

# A版和B版的板標點擊統計
SELECT g, remark, count(action) as c 
FROM plsport_playsport._app_action_log_3
GROUP BY g, remark;

        CREATE TABLE plsport_playsport._app_action_log_1_all engine=myisam # 所有的行為
        SELECT deviceid, abtestgroup, datetime, (case when (abtestgroup<11) then 'a' else 'b' end) as g 
        FROM plsport_playsport._app_action_log
        WHERE datetime between '2015-02-16 16:58:00' AND now()
        ORDER BY datetime DESC;

        CREATE TABLE plsport_playsport._app_action_log_1_all_1 engine=myisam
        SELECT g, deviceid, count(deviceid) as c
        FROM plsport_playsport._app_action_log_1_all
        GROUP BY g, deviceid;

# (1)A版和B版的裝置數統計(所有的人)
SELECT g, count(deviceid) as device_count 
FROM plsport_playsport._app_action_log_1_all_1
GROUP BY g;

# A: 7374
# B: 7300

# (2)A版和B版的裝置數統計(有點擊的人)
SELECT a.g, count(a.deviceid) as device_count
FROM (
    SELECT deviceid, g, count(action) as click_c 
    FROM plsport_playsport._app_action_log_3
    WHERE remark <> 'Click_Title_Default'
    GROUP BY deviceid, g) as a
GROUP BY a.g;

# A: 3777
# B: 3735

# 上面(1)和(2)可以先用ab testing計算機做檢驗
# http://getdatadriven.com/ab-significance-test

# A: 7374 > 3850 52%
# B: 7300 > 3735 51%

# 計算每人(每個裝置)點擊板標的次數
CREATE TABLE plsport_playsport._app_action_log_3_for_cal_avg_click engine = myisam
SELECT deviceid, g, count(action) as click_c 
FROM plsport_playsport._app_action_log_3
WHERE remark <> 'Click_Title_Default'
GROUP BY deviceid, g;

# 輸出txt給R跑t-test檢驗
SELECT 'deviceid', 'g', 'click' UNION (
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_app_action_log_3_for_cal_avg_click.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._app_action_log_3_for_cal_avg_click);


# to 靜怡: (2015-03-02) http://pm.playsport.cc/index.php/tasksComments?tasksId=4041&projectId=11
# 目前有以下幾點狀況:
# 
# 1. 煩請晨暐確定點擊預設版標是否已經有確定問題在那裡, 還是目前B版點擊不到版標是正常的.
# 2. 目前透過即時比分APP點擊而馬上購買的交易筆數很低, 所以目前無法得知參數設定的狀況
# 3. 同上, 因為交易筆數很低, 所以過完年後, 我們再來看看交易的筆數可以累績多少, 但照目前的情況來看, 可能需要訂立其它的指標
# 
# TO EDDY
# 預設版標的問題，工程目前找不到原因
# 麻煩年後再檢查一次狀況

# 第二次ABtesting已於2015-02-16 16:58上線

CREATE TABLE plsport_playsport._app_action_log engine=myisam 
SELECT * FROM
    plsport_playsport.app_action_log
WHERE
    app = 1 AND os = 1    #app=1即時比分, os=1是ANDriod 
    AND datetime between '2015-02-16 16:58:00' AND now()
    AND appversion in ( '2.2.4','2.2.5','2.2.6','2.2.7',
                        '2.2.8','2.2.9','2.3.0','2.3.1','2.3.2','2.3.3','2.3.4','2.3.4','2.3.5','2.3.6','2.3.7'); # ver2.2.4~2.3.1都是用新的log
                                                                  # 2.3.2 新增記錄坐標功能 (update:2015/1/27)
                                                                  # 2.3.4 在3/2還是最新的版本
                                                                  
CREATE TABLE plsport_playsport._app_action_log_1 engine=myisam # 撈出點擊板標記錄
SELECT * 
FROM plsport_playsport._app_action_log
WHERE action = 'clickTitle'
ORDER BY datetime DESC;

CREATE TABLE plsport_playsport._app_action_log_2 engine = myisam
SELECT appversion, userid, action, remark, datetime, deviceid, abtestgroup, devicemodel, deviceosversion  
FROM plsport_playsport._app_action_log_1
WHERE datetime between '2015-02-16 16:58:00' AND now();

CREATE TABLE plsport_playsport._app_action_log_3 engine = myisam
SELECT action, remark, datetime, deviceid, abtestgroup, (case when (abtestgroup<11) then 'a' else 'b' end) as g, devicemodel
FROM plsport_playsport._app_action_log_2
WHERE datetime between '2015-02-16 16:58:00' AND now(); # ABtesting已於1/15 9:30上線

SELECT g, remark, count(remark) as c 
FROM plsport_playsport._app_action_log_3
GROUP BY g, remark;

SELECT * FROM plsport_playsport._predict_buyer_with_cons
WHERE substr(position,1,3) = 'MSA'
AND buy_date between '2015-02-16 16:58:00' AND now();



# 2. 上次提到透過即時比分APP點擊而馬上購買的交易筆數很低 (2015-03-05)
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4041&projectId=11
# 這次從過年前(2015-02-16 16:58:00)~目前的區間來撈, 竟然只有1筆.....
# 很奇怪的是, 用iOS的人的交易筆數較多(有77筆), 用andorid的人只有1筆
# 所以根本完全沒辦法來abtesting
# 
# 後來我想到一招, 就是如果我們採用"透過即時比分APP點擊而馬上購買的交易"此條件可能太嚴格,
# 我這裡是可以做比較細的比對, 例如說:
# "透過即時比分APP點擊某殺手, 而當日有購買該殺手"就計算, 條件可能比較寬鬆一點, 而且也算合理
# 
# 我們需要討論看看妳和阿達是否同意改用這樣的觀察指標. 或是說有沒有其它建議, 至少原本的觀察指標是不可行的, 我們要想另一個我們都認同的觀察指標.

# 先執行上面的_app_action_log_1~_app_action_log_2

# http://pm.playsport.cc/index.php/tasksComments?tasksId=4041&projectId=11 2015-04-07


create table actionlog._title_click_from_app engine = myisam
SELECT userid, uri, time, platform_type
FROM actionlog.action_201502
where userid <> ''
and uri like '%rp=MSA%'
and time between '2015-02-16 16:58:00' AND now();

        insert ignore into actionlog._title_click_from_app
        SELECT userid, uri, time, platform_type
        FROM actionlog.action_201503
        where userid <> ''
        and uri like '%rp=MSA%'
        and time between '2015-02-16 16:58:00' AND now();

        insert ignore into actionlog._title_click_from_app
        SELECT userid, uri, time, platform_type
        FROM actionlog.action_201504
        where userid <> ''
        and uri like '%rp=MSA%'
        and time between '2015-02-16 16:58:00' AND now();


create table actionlog._title_click_from_app_1 engine = myisam
select a.userid, a.uri, a.time, a.platform_type, substr(a.p, 1, locate('&',a.p)-1) as killer
from (
    SELECT userid, uri, time, platform_type, substr(uri, locate('visit=',uri)+6, length(uri)) as p
    FROM actionlog._title_click_from_app) as a;

create table actionlog._title_click_from_app_2 engine = myisam
select a.userid, a.uri, a.time, a.platform_type, a.killer, substr(a.p, 1, locate('&',a.p)-1) as allianceid
from (
    SELECT userid, uri, time, platform_type, killer, substr(uri, locate('allianceid=',uri)+11, length(uri)) as p
    FROM actionlog._title_click_from_app_1) as a;

create table actionlog._title_click_from_app_3 engine = myisam
select a.userid, a.uri, a.time, a.platform_type, a.killer, a.allianceid, a.rp, right(a.rp, 1) as abtest
from (
    SELECT userid, uri, time, platform_type, killer, allianceid, substr(uri, locate('rp=',uri)+3, length(uri)) as rp
    FROM actionlog._title_click_from_app_2) as a 
where right(a.rp, 1) in ('A','B');

        ALTER TABLE plsport_playsport.predict_buyer ADD INDEX (`id_bought`);
        ALTER TABLE plsport_playsport.predict_seller ADD INDEX (`id`);

create table plsport_playsport._sellinfo engine = myisam
SELECT a.buyerid, a.buy_date, a.buy_gamedate as gamedate, b.sellerid as killer, a.buy_price as price, a.buy_allianceid as allianceid
FROM plsport_playsport.predict_buyer a left join plsport_playsport.predict_seller b on a.id_bought = b.id
where a.buy_date between '2015-02-16 16:58:00' AND now()
and a.buy_price <> 0;

select a.h, count(a.price)
from (
    SELECT hour(buy_date) as h, price 
    FROM plsport_playsport._sellinfo) as a
group by a.h;

        ALTER TABLE actionlog._title_click_from_app_3 CHANGE `killer` `killer` VARCHAR(32) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL;
        ALTER TABLE actionlog._title_click_from_app_3 CHANGE `allianceid` `allianceid` INT(4) NOT NULL;
        ALTER TABLE plsport_playsport._sellinfo ADD INDEX (`buyerid`,`killer`,`allianceid`);
        ALTER TABLE actionlog._title_click_from_app_3 ADD INDEX (`userid`,`killer`,`allianceid`);
        ALTER TABLE plsport_playsport._sellinfo convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._title_click_from_app_3 convert to character set utf8 collate utf8_general_ci;

create table actionlog._title_click_from_app_4 engine = myisam
SELECT a.buyerid, a.buy_date, a.gamedate, a.killer, a.price, a.allianceid, b.time as seetime, b.rp, b.abtest
FROM plsport_playsport._sellinfo a left join actionlog._title_click_from_app_3 b on a.buyerid = b.userid and a.killer = b.killer and a.allianceid = b.allianceid
where b.time is not null;

create table actionlog._title_click_from_app_5 engine = myisam
select *
from (
    SELECT buyerid, buy_date, gamedate, killer, price, allianceid, seetime, rp, abtest, round(TIME_TO_SEC(timediff(buy_date,seetime))/60,1) as difft #以分為單位
    FROM actionlog._title_click_from_app_4) as a
where a.difft < 23*60 and a.difft > 0; #點擊到實際購買的時間為>0且<23小時

#完成
create table actionlog._title_click_from_app_6 engine = myisam
SELECT buyerid, buy_date, gamedate, killer, price, allianceid, min(seetime) as seetime, rp, abtest, difft as mins
FROM actionlog._title_click_from_app_5
group by buyerid, buy_date, gamedate, killer, price, allianceid;


SELECT abtest, sum(price)
FROM actionlog._title_click_from_app_6
group by abtest;

# 
select a.abtest, count(a.buyerid)
from (
    SELECT buyerid, abtest, sum(price)
    FROM actionlog._title_click_from_app_6
    group by buyerid, abtest) as a
group by a.abtest;

# 準備要給R用的abtesting 名單
create table actionlog._title_click_from_app_7 engine = myisam
SELECT buyerid, abtest, sum(price) as spent
FROM actionlog._title_click_from_app_6
group by buyerid, abtest;

SELECT 'userid', 'abtest', 'spent' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_title_click_from_app_7.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._title_click_from_app_7);















# =================================================================================================
# 任務: 研究月底業績趨向 [新建] (阿達) 2015-01-19
# 說明
# 
# 研究月底( 21~30)跟其他時段是否有差異，如果有差異，可考慮調整單殺規則
# 負責人：Eddy
#  
# 研究內容
#  
# 1. 整體業績
# 2. 單場殺手、雙重殺手販售額
# =================================================================================================

# 此任務主要應觀察購買預測金額, 而不是儲值噱幣, 應撈pcash_log

use revenue;

/*處理pcash_log, 會員購買預測的相關資訊*/
CREATE TABLE _pcash_log engine = myisam
SELECT userid, amount, date(date) as c_date, month(date) as c_month, year(date) as c_year, substr(date,1,7) as ym, id_this_type
FROM pcash_log
WHERE payed = 1 AND type = 1
AND date between '2012-01-01 00:00:00' AND now();

CREATE TABLE revenue._predict_seller_with_medal engine = myisam
SELECT id, sellerid, mode, sale_allianceid, sale_gameid, sale_date, substr(sale_date,1,7) as m, substr(sale_date,1,10) as d, sale_price, buyer_count, rank, rank_sk, selltype,
       (case when (selltype = 1) then '莊殺'
             when (selltype = 2) then '單殺'
             when (selltype = 3) then '雙殺' end ) as killtype,
       (case when (rank <11 AND selltype = 1) then '金牌'
             when (rank <31 AND selltype = 1) then '銀牌'
             when (rank <52 AND selltype = 1) then '銅牌'
             when (rank_sk< 11 AND selltype = 2) then '金牌'
             when (rank_sk< 31 AND selltype = 2) then '銀牌'
             when (rank_sk< 52 AND selltype = 2) then '銅牌'
             when (rank < 11 AND selltype = 3) then '金牌'
             when (rank_sk < 11 AND selltype = 3) then '金牌' else '銀牌' end) as killmedal     
FROM revenue.predict_seller /*最好是指定精確的日期區間*/
WHERE sale_date between '2011-12-15 00:00:00' AND now(); /*<====記得要改*/

CREATE TABLE revenue._alliance engine = myisam
SELECT allianceid, alliancename
FROM revenue.alliance;

        ALTER TABLE  _pcash_log ADD INDEX (`id_this_type`);       /*index*/
        ALTER TABLE  _predict_seller_with_medal ADD INDEX (`id`); /*index*/
        ALTER TABLE  _alliance ADD INDEX (`allianceid`);          /*index*/

CREATE TABLE _pcash_log_with_detailed_info engine = myisam
SELECT c.userid, c.amount, c.c_date, c.c_month, c.c_year, c.ym,
       c.id, c.sellerid, c.sale_allianceid, d.alliancename, c.sale_date, c.sale_price, c.killtype, c.killmedal
FROM (
    SELECT a.userid, a.amount, a.c_date, a.c_month, a.c_year, a.ym, 
           b.id, b.sellerid, b.sale_allianceid, b.sale_date, b.sale_price, b.killtype, b.killmedal
    FROM revenue._pcash_log a LEFT JOIN revenue._predict_seller_with_medal b on a.id_this_type = b.id) as c
LEFT JOIN _alliance as d on c.sale_allianceid = d.allianceid;

CREATE TABLE _pcash_log_with_detailed_info_1 engine = myisam
SELECT userid, amount, c_date as date, substr(c_date,1,7) as m, substr(c_date,9,2) as d, sellerid, sale_allianceid, alliancename, killtype, killmedal  
FROM revenue._pcash_log_with_detailed_info;

CREATE TABLE _pcash_log_with_detailed_info_2 engine = myisam
SELECT userid, amount, date, m, d, 
       (case when (d<11) then 'early' when (d<21) then 'mid' else 'late' end) as p,
       sellerid, sale_allianceid, alliancename, killtype, killmedal
FROM revenue._pcash_log_with_detailed_info_1;

# 全體業績
SELECT m, p, sum(amount) as sale 
FROM revenue._pcash_log_with_detailed_info_2
GROUP BY m, p;

# 分組業績 - 單場殺手
SELECT m, p, sum(amount) as sale 
FROM revenue._pcash_log_with_detailed_info_2
WHERE killtype = '單殺'
GROUP BY m, p;

SELECT m, p, sum(amount) as sale 
FROM revenue._pcash_log_with_detailed_info_2
WHERE killtype = '莊殺'
GROUP BY m, p;

SELECT m, p, sum(amount) as sale 
FROM revenue._pcash_log_with_detailed_info_2
WHERE killtype = '雙殺'
GROUP BY m, p;


# =================================================================================================
# 任務: [201411-D-3]開發討論區會員等級-工程測試名單撈取 [新建] (靜怡) 2015-01-22
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4199&projectId=11
# 提供測試名單
# 內容
#  
# - 撈取在討論區活躍的使用者20名
#     發文、回文、推數高者
#     撰寫分析文高者
# 
# - 提供時間:1/22
# =================================================================================================

CREATE TABLE plsport_playsport._post_count engine = myisam
SELECT postuser, count(subjectid) as post_count 
FROM plsport_playsport.forum
WHERE postuser <> ''
GROUP BY postuser;


CREATE TABLE plsport_playsport._reply_count engine = myisam
SELECT userid, count(subjectid) as reply_count 
FROM plsport_playsport.forumcontent
WHERE userid <> ''
GROUP BY userid;

CREATE TABLE plsport_playsport._LIKE_count engine = myisam
SELECT postuser, sum(pushcount) as got_LIKE 
FROM plsport_playsport.forum
WHERE postuser <> ''
GROUP BY postuser;

CREATE TABLE plsport_playsport._analysis_count engine = myisam
SELECT postuser, count(subjectid) as analysis_count
FROM plsport_playsport.forum
WHERE gametype = 1
AND postuser <> ''
GROUP BY postuser;

CREATE TABLE plsport_playsport._post_count_1 engine = myisam
SELECT postuser, post_count, round((cnt-rank+1)/cnt,2) as post_p
FROM (SELECT postuser, post_count, @curRank := @curRank + 1 AS rank
      FROM plsport_playsport._post_count, (SELECT @curRank := 0) r
      ORDER BY post_count DESC) as dt,
     (SELECT count(distinct postuser) as cnt FROM plsport_playsport._post_count) as ct;

CREATE TABLE plsport_playsport._reply_count_1 engine = myisam
SELECT userid, reply_count, round((cnt-rank+1)/cnt,2) as reply_p
FROM (SELECT userid, reply_count, @curRank := @curRank + 1 AS rank
      FROM plsport_playsport._reply_count, (SELECT @curRank := 0) r
      ORDER BY reply_count DESC) as dt,
     (SELECT count(distinct userid) as cnt FROM plsport_playsport._reply_count) as ct;

CREATE TABLE plsport_playsport._LIKE_count_1 engine = myisam
SELECT postuser, got_LIKE, round((cnt-rank+1)/cnt,2) as LIKE_p
FROM (SELECT postuser, got_LIKE, @curRank := @curRank + 1 AS rank
      FROM plsport_playsport._LIKE_count, (SELECT @curRank := 0) r
      ORDER BY got_LIKE DESC) as dt,
     (SELECT count(distinct postuser) as cnt FROM plsport_playsport._LIKE_count) as ct;

CREATE TABLE plsport_playsport._analysis_count_1 engine = myisam
SELECT postuser, analysis_count, round((cnt-rank+1)/cnt,2) as analysis_p
FROM (SELECT postuser, analysis_count, @curRank := @curRank + 1 AS rank
      FROM plsport_playsport._analysis_count, (SELECT @curRank := 0) r
      ORDER BY analysis_count DESC) as dt,
     (SELECT count(distinct postuser) as cnt FROM plsport_playsport._analysis_count) as ct;

        ALTER TABLE plsport_playsport._post_count_1 ADD INDEX (`postuser`);     /*index*/
        ALTER TABLE plsport_playsport._reply_count_1 ADD INDEX (`userid`);      /*index*/
        ALTER TABLE plsport_playsport._LIKE_count_1 ADD INDEX (`postuser`);     /*index*/
        ALTER TABLE plsport_playsport._analysis_count_1 ADD INDEX (`postuser`); /*index*/

CREATE TABLE plsport_playsport._list1 engine = myisam
SELECT a.userid, a.nickname, b.post_count, b.post_p
FROM plsport_playsport.member a LEFT JOIN plsport_playsport._post_count_1 b on a.userid = b.postuser;

CREATE TABLE plsport_playsport._list2 engine = myisam
SELECT a.userid, a.nickname, a.post_count, a.post_p, b.reply_count, b.reply_p
FROM plsport_playsport._list1 a LEFT JOIN plsport_playsport._reply_count_1 b on a.userid = b.userid
WHERE b.reply_count is not null;

CREATE TABLE plsport_playsport._list3 engine = myisam
SELECT a.userid, a.nickname, a.post_count, a.post_p, a.reply_count, a.reply_p, b.got_LIKE, b.LIKE_p
FROM plsport_playsport._list2 a LEFT JOIN plsport_playsport._LIKE_count_1 b on a.userid = b.postuser;

CREATE TABLE plsport_playsport._list4 engine = myisam
SELECT a.userid, a.nickname, a.post_count, a.post_p, a.reply_count, a.reply_p, a.got_LIKE, a.LIKE_p, b.analysis_count, b.analysis_p
FROM plsport_playsport._list3 a LEFT JOIN plsport_playsport._analysis_count_1 b on a.userid = b.postuser;

CREATE TABLE plsport_playsport._list5 engine = myisam
SELECT * 
FROM plsport_playsport._list4
WHERE post_count is not null
AND post_p > 0.98 # 發文需在前98%
AND analysis_count is not null
ORDER BY analysis_count DESC;

SELECT 'userid', 'nickname', '貼文', '%','回文','%','得到推','%','分析文','%' UNION (
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/forum_level_simulator.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._list5);



# =================================================================================================
# 任務: [201406-A-8] 個人預測頁左下欄位改成戰績 - A/B testing [新建] (阿達) 2015-01-30
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4068&projectId=11
# 說明
# 執此任務 A/B testing
# 負責人：Eddy
# 時間：
# 提供測試名單  12/31
# 測試報告      2/4
# =================================================================================================

CREATE TABLE actionlog.action_visit_member_check engine = myisam
SELECT * FROM actionlog.action_201501
WHERE time between '2015-01-05 12:00:00' AND '2015-01-31 23:59:59'
AND uri LIKE '%visit_member.php%';

INSERT IGNORE INTO actionlog.action_visit_member_check
SELECT * FROM actionlog.action_201502
WHERE time between '2015-02-01 00:00:00' AND now()
AND uri LIKE '%visit_member.php%';

CREATE TABLE actionlog.action_visit_member_check_1 engine = myisam
SELECT userid, uri, time
FROM actionlog.action_visit_member_check
WHERE userid <> ''
AND ((uri LIKE '%post_FROM%') or (uri LIKE '%click_FROM%'));

CREATE TABLE actionlog.action_visit_member_check_2 engine = myisamp
SELECT userid, uri, time, (case when (locate('click_FROM=',uri)>0) then substr(uri,locate('click_FROM=',uri)+11, length(uri)) else '' end) as click,
                          (case when (locate('post_FROM=' ,uri)>0) then substr(uri,locate('post_FROM=' ,uri)+10, length(uri)) else '' end) as post
FROM actionlog.action_visit_member_check_1;

CREATE TABLE actionlog.action_visit_member_check_3 engine = myisam
SELECT userid, uri, time, concat(click,post) as c
FROM actionlog.action_visit_member_check_2;

        ALTER TABLE actionlog.action_visit_member_check_3 convert to character SET utf8 collate utf8_general_ci;
        ALTER TABLE actionlog.action_visit_member_check_3 ADD INDEX (`userid`);

CREATE TABLE actionlog.action_visit_member_check_4 engine = myisam
SELECT (case when (c.g<7) then 'a' else 'b' end) as abtest, c.g, c.userid, c.uri, c.time, c.c 
FROM (
    SELECT (b.id%20)+1 as g, a.userid, a.uri, a.time, a.c 
    FROM actionlog.action_visit_member_check_3 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid) as c;

SELECT abtest, c, count(userid) as click_count 
FROM actionlog.action_visit_member_check_4 
GROUP BY abtest, c;



CREATE TABLE actionlog.action_forumdetail_check engine = myisam
SELECT * FROM actionlog.action_201501
WHERE time between '2015-01-05 12:00:00' AND '2015-01-31 23:59:59'
AND uri LIKE '%forumdetail.php%';

INSERT IGNORE INTO actionlog.action_forumdetail_check
SELECT * FROM actionlog.action_201502
WHERE time between '2015-02-01 00:00:00' AND now()
AND uri LIKE '%forumdetail.php%';

CREATE TABLE actionlog.action_forumdetail_check_1 engine = myisam
SELECT userid, uri, time 
FROM actionlog.action_forumdetail_check
WHERE uri LIKE '%post_FROM=VMP%' AND userid <> '';

CREATE TABLE actionlog.action_forumdetail_check_2 engine = myisam
SELECT userid, uri, time, substr(uri, locate('post_FROM=',uri)+10, length(uri)) as p
FROM actionlog.action_forumdetail_check_1;

SELECT p, count(userid) as c 
FROM actionlog.action_forumdetail_check_2
GROUP BY p;

CREATE TABLE plsport_playsport._everyone_spent engine = myisam
SELECT userid, sum(amount) as spent 
FROM plsport_playsport.pcash_log
WHERE payed = 1 AND type = 1
AND date between '2015-01-05 12:00:00' AND now()
GROUP BY userid;

CREATE TABLE plsport_playsport._everyone_spent_1 engine = myisam
SELECT (b.id%20)+1 as g, a.userid, a.spent 
FROM plsport_playsport._everyone_spent a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

CREATE TABLE plsport_playsport._everyone_spent_2 engine = myisam
SELECT g, (case when (g<7) then 'a' else 'b' end) as abtest, userid, spent 
FROM plsport_playsport._everyone_spent_1;

SELECT abtest, count(userid), sum(spent) 
FROM plsport_playsport._everyone_spent_2
GROUP BY abtest;

SELECT 'abtest', 'userid', 'spent' UNION (
SELECT abtest, userid, spent
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_everyone_spent_2.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._everyone_spent_2);



# =================================================================================================
# 任務: [201412-E-7] NBA即時比分新增團隊數據 - 問卷與數據統計 [新建] (阿達) 2015-01-30
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4190&projectId=11
# 統計NBA即時比分新增團隊數據及即時比分顯示隔日賽事數據兩任務的問卷及相關數據
# 負責人：Eddy
# 時間：
# 問卷 2/2
# 團隊數據點擊量、隔日賽事點擊量 2/26
# 
# 內容
# 1. 分析問卷結果
#    a. 剃除填寫時間太長及太短的問卷
#    b. 在1/26(含)前沒有點選過”數據▼”的使用者，則不記入他第一、二題的回答
# 2. 團隊數據點擊量
#    a. 統計”數據▼”的點擊量，及使用比例( 多少使用者使用)
# 3. 隔日賽事點擊量
#    a. 統計預測比例、對戰紀錄點擊量
#    b. 統計1/22(含)後，看隔日賽事的使用者是否有增加
# =================================================================================================

# 匯入(1)event(這張表在linode中)
#     (2)plsport_playsport.questionnaire_livescoreTeamStat_answer

CREATE TABLE plsport_playsport._events engine = myisam
SELECT userid, time 
FROM plsport_playsport.events
WHERE userid <> ''
AND time between '2015-01-21 10:41:56' AND now();

CREATE TABLE plsport_playsport._events_1 engine = myisam
SELECT userid, min(time) as use_time 
FROM plsport_playsport._events
GROUP BY userid;

CREATE TABLE plsport_playsport._qu engine = myisam
SELECT userid, write_time, spend_minute, question01, question02, question03, question04, question05
FROM plsport_playsport.questionnaire_livescoreteamstat_answer
WHERE spend_minute>0.4;

CREATE TABLE plsport_playsport._qu1 engine = myisam
SELECT *
FROM plsport_playsport._qu
WHERE spend_minute<10;

        ALTER TABLE plsport_playsport._qu1 convert to character SET utf8 collate utf8_general_ci;
        ALTER TABLE plsport_playsport._events_1 convert to character SET utf8 collate utf8_general_ci;

CREATE TABLE plsport_playsport._qu_with_use_time engine = myisam
SELECT a.userid, a.write_time, b.use_time, a.spend_minute, a.question01 as q1, a.question02 as q2, a.question03 as q3, a.question04 as q4, a.question05 as q5 
FROM plsport_playsport._qu1 a LEFT JOIN plsport_playsport._events_1 b on a.userid = b.userid;

CREATE TABLE plsport_playsport._qu_with_use_time_1 engine = myisam
SELECT userid, write_time, use_time, TIME_TO_SEC(timediff(write_time, use_time)) as s, q1, q2, q3, q4, q5
FROM plsport_playsport._qu_with_use_time;

CREATE TABLE plsport_playsport._qu_analysis1 engine = myisam
SELECT userid, s, q1, q2 
FROM plsport_playsport._qu_with_use_time_1
WHERE s > 0;

SELECT q1, count(userid) as c 
FROM plsport_playsport._qu_analysis1
GROUP BY q1;

SELECT q2, count(userid) as c 
FROM plsport_playsport._qu_analysis1
GROUP BY q2;

SELECT q5, count(userid) as c 
FROM plsport_playsport._qu_with_use_time_1
GROUP BY q5;

CREATE TABLE plsport_playsport._qu_analysis2 engine = myisam
SELECT userid, (case when (q4 LIKE '%1%') then 1 else 0 end) as t1,
               (case when (q4 LIKE '%2%') then 1 else 0 end) as t2,
               (case when (q4 LIKE '%3%') then 1 else 0 end) as t3,
               (case when (q4 LIKE '%4%') then 1 else 0 end) as t4,
               (case when (q4 LIKE '%5%') then 1 else 0 end) as t5
FROM plsport_playsport._qu_with_use_time_1;


# ------------------------------------------------------
# 團隊數據點擊量、隔日賽事點擊量 2/26 (阿達)
#     2. 團隊數據點擊量
#        a. 統計”數據▼”的點擊量，及使用比例(多少使用者使用)
#     3. 隔日賽事點擊量
#        a. 統計預測比例、對戰紀錄點擊量
#        b. 統計1/22(含)後，看隔日賽事的使用者是否有增加
# ------------------------------------------------------

# 文婷說此問券常常有受訪者答非所問的情況 2015-03-03

# 先匯入events(已寫成.py)

# (1)先撈出所有即時比分的pv
CREATE TABLE actionlog._livescore engine = myisam SELECT userid, uri, time FROM actionlog.action_201504 WHERE uri LIKE '%/livescore%' and userid <> '';
INSERT IGNORE INTO actionlog._livescore SELECT userid, uri, time FROM actionlog.action_201505 WHERE uri LIKE '%/livescore%' and userid <> '';
INSERT IGNORE INTO actionlog._livescore SELECT userid, uri, time FROM actionlog.action_201506 WHERE uri LIKE '%/livescore%' and userid <> '';

# 預測比例
CREATE TABLE actionlog._predictgame engine = myisam SELECT userid, uri, time FROM actionlog.action_201504 WHERE uri LIKE '%/predictgame.php%' and userid <> '';
INSERT IGNORE INTO actionlog._predictgame SELECT userid, uri, time FROM actionlog.action_201505 WHERE uri LIKE '%/predictgame.php%' and userid <> '';
INSERT IGNORE INTO actionlog._predictgame SELECT userid, uri, time FROM actionlog.action_201506 WHERE uri LIKE '%/predictgame.php%' and userid <> '';
# 賽事數據
CREATE TABLE actionlog._games_data engine = myisam SELECT userid, uri, time FROM actionlog.action_201504 WHERE uri LIKE '%/games_data.php%' and userid <> '';
INSERT IGNORE INTO actionlog._games_data SELECT userid, uri, time FROM actionlog.action_201505 WHERE uri LIKE '%/games_data.php%' and userid <> '';
INSERT IGNORE INTO actionlog._games_data SELECT userid, uri, time FROM actionlog.action_201506 WHERE uri LIKE '%/games_data.php%' and userid <> '';

        # 預測比例(所有人)
        CREATE TABLE actionlog._predictgame_without_login engine = myisam SELECT userid, uri, time FROM actionlog.action_201504 WHERE uri LIKE '%/predictgame.php%';
        INSERT IGNORE INTO actionlog._predictgame_without_login SELECT userid, uri, time FROM actionlog.action_201505 WHERE uri LIKE '%/predictgame.php%';
        INSERT IGNORE INTO actionlog._predictgame_without_login SELECT userid, uri, time FROM actionlog.action_201506 WHERE uri LIKE '%/predictgame.php%';        
        # 賽事數據(所有人)
        CREATE TABLE actionlog._games_data_without_login engine = myisam SELECT userid, uri, time FROM actionlog.action_201504 WHERE uri LIKE '%/games_data.php%';
        INSERT IGNORE INTO actionlog._games_data_without_login SELECT userid, uri, time FROM actionlog.action_201505 WHERE uri LIKE '%/games_data.php%'; 
        INSERT IGNORE INTO actionlog._games_data_without_login SELECT userid, uri, time FROM actionlog.action_201506 WHERE uri LIKE '%/games_data.php%';       
# (2)再區分出那些人是只看NBA


# 處理造訪即時比分頁預設的聯盟(NBA OR MLB)
CREATE TABLE actionlog._livescore_1_1 engine = myisam
SELECT a.userid, a.uri, a.time, (case when (locate('&',a.t)=0) then a.t else substr(a.t,1,locate('&',a.t)-1) end) as p
FROM (
    SELECT userid, uri, time, (case when (locate('aid=',uri)=0) then 3 else substr(uri, locate('aid=',uri)+4, length(uri)) end) as t
    FROM actionlog._livescore
    where time between '2014-12-01 00:00:00' and '2015-04-31 23:59:59') as a; # 4/1之前, 如果造訪livescore.php, 預設聯盟是NBA

CREATE TABLE actionlog._livescore_1_2 engine = myisam
SELECT a.userid, a.uri, a.time, (case when (locate('&',a.t)=0) then a.t else substr(a.t,1,locate('&',a.t)-1) end) as p
FROM (
    SELECT userid, uri, time, (case when (locate('aid=',uri)=0) then 1 else substr(uri, locate('aid=',uri)+4, length(uri)) end) as t
    FROM actionlog._livescore
    where time between '2015-04-01 00:00:00' and now()) as a;                 # 4/1之後, 如果造訪livescore.php, 預設聯盟是MLB

# merge
create table actionlog._livescore_1 engine = myisam
SELECT * FROM actionlog._livescore_1_1;
insert ignore into actionlog._livescore_1
SELECT * FROM actionlog._livescore_1_2;

CREATE TABLE actionlog._livescore_2 engine = myisam
SELECT * 
FROM actionlog._livescore_1
WHERE length(p) in (1,2) AND p = 1; # 只篩選出aid是NBA

CREATE TABLE plsport_playsport._livescore_usage engine = myisam
SELECT a.userid, a.d, count(a.userid) as c
FROM (
    SELECT userid, date(time) as d 
    FROM actionlog._livescore_2) as a
WHERE a.userid <> ''
GROUP BY a.userid, a.d;

        # a.每天NBA即時比分使用的人數
        SELECT d, count(userid) as user_count
        FROM plsport_playsport._livescore_usage
        GROUP BY d;

# MLB 沒有隔日數據, 數據▼ 
# CREATE TABLE plsport_playsport._click_record_team_open engine = myisam # 有登入的
# SELECT id, userid, name, date(time) as d
# FROM plsport_playsport.events
# WHERE userid <> ''
# AND name LIKE '%livescore_record_team%';
# 
# CREATE TABLE plsport_playsport._click_record_team_open_without_login engine = myisam # 所有人(含沒登入的)
# SELECT id, userid, name, date(time) as d
# FROM plsport_playsport.events
# WHERE name LIKE '%livescore_record_team%';
# 
#         # b.統計”數據▼”的點擊量，(所有人(含沒登入的))
#         SELECT d, count(name) as c 
#         FROM plsport_playsport._click_record_team_open_without_login
#         GROUP BY d;
# 
#         # c.及使用比例(多少使用者使用)
#         SELECT a.d, count(a.userid) as user_click_count
#         FROM (
#             SELECT userid, d, count(name) as c 
#             FROM plsport_playsport._click_record_team_open
#             GROUP BY userid, d) as a
#         GROUP BY a.d;


CREATE TABLE plsport_playsport._livescore_nextday_1 engine = myisam
SELECT a.userid, a.uri, a.time, substr(a.c,1,8) as nextday
FROM (
    SELECT userid, uri, time, (case when (locate('gamedate=', uri)=0) then "" else substr(uri,locate('gamedate=', uri)+9,length(uri)) end) as c
    FROM actionlog._livescore_2
    WHERE p = 1) as a; # 只限看MLB

        CREATE TABLE plsport_playsport._livescore_nextday_2 engine = myisam
        SELECT userid, uri, date(time) as today, str_to_date(nextday, '%Y%m%d') as nextday, datediff(str_to_date(nextday, '%Y%m%d'), date(time)) as s
        FROM plsport_playsport._livescore_nextday_1
        WHERE nextday <> '';

        #抽出點選明天的人
        CREATE TABLE plsport_playsport._livescore_nextday_3 engine = myisam
        SELECT * FROM plsport_playsport._livescore_nextday_2
        WHERE s = 1;

        # d.有多少人會去點擊隔日賽事
        SELECT a.today, count(a.userid) as c
        FROM (
            SELECT userid, today, count(uri) as c 
            FROM plsport_playsport._livescore_nextday_3
            GROUP BY userid, today) as a
        GROUP BY a.today;

        # e.統計預測比例人數
        SELECT b.d, count(b.userid) as user_count
        FROM (
            SELECT a.d, a.userid, count(a.uri) as c
            FROM (
                SELECT userid, uri, date(time) as d 
                FROM actionlog._predictgame
                WHERE uri LIKE '%FROM=livescore%') as a
            GROUP BY a.d, a.userid) as b
        GROUP BY b.d;

        # f.對戰紀錄人數
        SELECT b.d, count(b.userid) as user_count
        FROM (
            SELECT a.d, a.userid, count(a.uri) as c
            FROM (
                SELECT userid, uri, date(time) as d 
                FROM actionlog._games_data
                WHERE uri LIKE '%FROM=livescore%') as a
            GROUP BY a.d, a.userid) as b
        GROUP BY b.d;

# g.預測比例點擊數 (所有人)
SELECT a.d, count(a.uri) as c
FROM (
    SELECT userid, uri, date(time) as d 
    FROM actionlog._predictgame_without_login
    WHERE uri LIKE '%FROM=livescore%') as a
GROUP BY a.d;

# h.對戰紀錄點擊數 (所有人)
SELECT a.d, count(a.uri) as c
FROM (
    SELECT userid, uri, date(time) as d 
    FROM actionlog._games_data_without_login
    WHERE uri LIKE '%FROM=livescore%') as a
GROUP BY a.d;



# =================================================================================================
# 任務: 撈取分析文問卷名單 [新建] (學文) 2015-02-06
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4273&projectId=11
# to eddy
# 要麻煩您協助撈取　近一年有寫過三篇（含）以上分析文的使用者名單
# 要做為分析文問卷的名單
# 因為這個問卷比較趕，最晚希望能再下禮拜一就上線
# 所以可能要麻煩您今天或明天產出名單
# =================================================================================================

# 先匯入forum


CREATE TABLE plsport_playsport._analysis_user_list engine = myisam
SELECT a.postuser, count(a.subjectid) as analysis_post_count
FROM (
    SELECT subjectid, postUser, posttime, allianceid, date(posttime) as d, substr(posttime,1,7) as m, year(posttime) as y 
    FROM plsport_playsport.forum
    WHERE gametype = 1 # 分析文
    AND posttime between subdate(now(),365) AND now() # 近一年
    ORDER BY posttime) as a
GROUP BY a.postuser;


    SELECT subjectid, subject, postUser, posttime, allianceid, date(posttime) as d, substr(posttime,1,7) as m, year(posttime) as y 
    FROM plsport_playsport.forum
    WHERE gametype = 1 # 分析文
    AND posttime between subdate(now(),365) AND now() # 近一年
    ORDER BY posttime;


CREATE TABLE plsport_playsport._analysis_user_list_nickname engine = myisam
SELECT a.postuser as userid, b.nickname, a.analysis_post_count 
FROM plsport_playsport._analysis_user_list a LEFT JOIN plsport_playsport.member b on a.postuser = b.userid
WHERE a.analysis_post_count > 2
ORDER BY a.analysis_post_count DESC;

UPDATE plsport_playsport._analysis_user_list_nickname SET nickname = TRIM(nickname);            #刪掉空白字完
update plsport_playsport._analysis_user_list_nickname SET nickname = replace(nickname, '.',''); #清除nickname奇怪的符號...
update plsport_playsport._analysis_user_list_nickname SET nickname = replace(nickname, ',','');
update plsport_playsport._analysis_user_list_nickname SET nickname = replace(nickname, ';','');
update plsport_playsport._analysis_user_list_nickname SET nickname = replace(nickname, '%','');
update plsport_playsport._analysis_user_list_nickname SET nickname = replace(nickname, '/','');
update plsport_playsport._analysis_user_list_nickname SET nickname = replace(nickname, '/','');
update plsport_playsport._analysis_user_list_nickname SET nickname = replace(nickname, '\\','_');
update plsport_playsport._analysis_user_list_nickname SET nickname = replace(nickname, '*','');
update plsport_playsport._analysis_user_list_nickname SET nickname = replace(nickname, '#','');
update plsport_playsport._analysis_user_list_nickname SET nickname = replace(nickname, '&','');
update plsport_playsport._analysis_user_list_nickname SET nickname = replace(nickname, '$','');

SELECT 'userid', 'nickname', '分析文數' UNION (
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/analysis_user_list_nickname.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._analysis_user_list_nickname);

SELECT 'userid' UNION (
SELECT userid
INTO outfile 'C:/Users/1-7_ASUS/Desktop/analysis_user_list_nickname_for_engineer.txt'
fields terminated by ',' enclosed by '' lines terminated by '\r\n'
FROM plsport_playsport._analysis_user_list_nickname);


# =================================================================================================
# 新增專案: 行銷企劃 - 分析文問卷分析 [任務] (學文) 2015-02-12
# 此任務的內容是延續上面的任務
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4306&projectId=11
# to eddy
# 
# 分析文問卷會在明日早上10:00跑完
# 要麻煩您從結果中幫我們撈 "從11月開始到現在，有寫過五篇（含）已上的分析文"的做情況
# 問卷結果在這裡
# http://www.playsport.cc/questionnaire.php?question=201502051635358958&action=statistics
# 明天早上10:00問卷才會跑完唷~
# 謝謝!
# =================================================================================================

# 1. 要先匯入TABLE: questionnaire_201502051635358958_answer
# 2. 再匯入forum

CREATE TABLE plsport_playsport._analysis_user_list engine = myisam
SELECT a.postuser, count(a.subjectid) as analysis_post_count
FROM (
    SELECT subjectid, postUser, posttime, allianceid, date(posttime) as d, substr(posttime,1,7) as m, year(posttime) as y 
    FROM plsport_playsport.forum
    WHERE gametype = 1 # 分析文
    AND posttime between '2014-11-01 00:00:00' AND now() # 近一年
    ORDER BY posttime) as a
GROUP BY a.postuser;


CREATE TABLE plsport_playsport._analysis_user_list_nickname engine = myisam
SELECT a.postuser as userid, b.nickname, a.analysis_post_count 
FROM plsport_playsport._analysis_user_list a LEFT JOIN plsport_playsport.member b on a.postuser = b.userid
WHERE a.analysis_post_count >= 5
ORDER BY a.analysis_post_count DESC;

# 如果欄位是數字命名的, 就要用``括起來
        ALTER TABLE plsport_playsport.questionnaire_201502051635358958_answer CHANGE `1423205622` q1 INT(1);
        ALTER TABLE plsport_playsport.questionnaire_201502051635358958_answer CHANGE `1423205651` q2 INT(1);
        ALTER TABLE plsport_playsport.questionnaire_201502051635358958_answer CHANGE `1423205678` q3 INT(1);
        ALTER TABLE plsport_playsport.questionnaire_201502051635358958_answer CHANGE `1423205718` q4 text;

        update plsport_playsport.questionnaire_201502051635358958_answer SET q4 = TRIM(TRAILING '\\' FROM q4);
        update plsport_playsport.questionnaire_201502051635358958_answer SET q4 = TRIM(TRAILING ' ' FROM q4);
        update plsport_playsport.questionnaire_201502051635358958_answer SET q4 = replace(q4, ' ','');
        update plsport_playsport.questionnaire_201502051635358958_answer SET q4 = replace(q4, '\\','');
        update plsport_playsport.questionnaire_201502051635358958_answer SET q4 = replace(q4, '\n','');
        update plsport_playsport.questionnaire_201502051635358958_answer SET q4 = replace(q4, '\r','');
        update plsport_playsport.questionnaire_201502051635358958_answer SET q4 = replace(q4, '\t','');


CREATE TABLE plsport_playsport._qu_1 engine = myisam
SELECT a.userid, b.nickname, a.q1, a.q2, a.q3, a.q4, b.analysis_post_count
FROM plsport_playsport.questionnaire_201502051635358958_answer a inner join plsport_playsport._analysis_user_list_nickname b on a.userid = b.userid;

CREATE TABLE plsport_playsport._qu_2 engine = myisam
SELECT userid, q1,q2,q3,q4 
FROM plsport_playsport.questionnaire_201502051635358958_answer;



# =================================================================================================
# 任務: [201408-A-11]開發回文推功能-第二次發文推樣式ABtesting [新建]
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4258&projectId=11
# 說明
# 目的：了解新的發文推介面是否吸引使用者
#  
# 內容
# - 測試時間：待補
# - 設定測試組別
# - 觀察指標：1.發文推點擊次數、2.發文推比
# - 報告時間：請於2/24先確認狀況，再評估是否要繼續執行
# =================================================================================================

# - 目前的版本:pushit_bottom_a
# - 舊的版本:  pushit_bottom_b
# 要先匯入linode上的events

CREATE TABLE plsport_playsport._events engine = myisam
SELECT * 
FROM plsport_playsport.events
WHERE name LIKE '%pushit_bottom%'
AND time between '2015-02-06 14:45:00' AND now();

    ALTER TABLE plsport_playsport._events convert to character SET utf8 collate utf8_general_ci;

CREATE TABLE plsport_playsport._events_with_group engine = myisam
SELECT c.g, (case when (c.g<11) then 'a' else 'b' end) as abtest, c.userid, c.name, c.time
FROM (
    SELECT (b.id%20)+1 as g, a.userid, a.name, a.time 
    FROM plsport_playsport._events a LEFT JOIN plsport_playsport.member b on a.userid = b.userid) as c;

# 完成
SELECT abtest, name, count(userid) as c 
FROM plsport_playsport._events_with_group
GROUP BY abtest, name;


# =================================================================================================
# 任務: 紅陽金流程式串接 - A/B testing [新建] (阿達) 2015-02-13
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4145&projectId=11
# 要先匯入
#    (1) member
#    (2) order_data
# =================================================================================================
# To Eddy：
# 因主機更換，我於 2/11 00:11開始關閉紅陽金流


        CREATE TABLE plsport_playsport._order_data_check_a engine = myisam
        SELECT id, userid, CREATEon, ordernumber, price, payway, sellconfirm, CREATE_FROM, platform_type 
        FROM plsport_playsport.order_data
        WHERE CREATEon between '2015-01-14 15:12:00' AND '2015-02-11 00:00:00' # 主機受到攻擊前
        AND platform_type in (2,3) # 手機/平板
        AND payway in (1,10)       # 1: 一般信用卡, 2:紅陽
        AND userid not in ('a9991','wayway1974','ydasam')  # 這個是測試帳號
        AND substr(userid,1,9) <> 'ckone1209';             # 這個是測試帳號

        # 2015-02-16 13:36已將測試名單改為(userid%20)+1 in (7,8,9,10,11,12,13,14), 佔比為全站40%
        CREATE TABLE plsport_playsport._order_data_check_b engine = myisam
        SELECT id, userid, CREATEon, ordernumber, price, payway, sellconfirm, CREATE_FROM, platform_type 
        FROM plsport_playsport.order_data
        WHERE CREATEon between '2015-02-16 13:36:00' AND now() # 主機受到攻擊前
        AND platform_type in (2,3) # 手機/平板
        AND payway in (1,10)       # 1: 一般信用卡, 2:紅陽
        AND userid not in ('a9991','wayway1974','ydasam')  # 這個是測試帳號
        AND substr(userid,1,9) <> 'ckone1209';             # 這個是測試帳號


CREATE TABLE plsport_playsport._order_data_check_a_1 engine = myisam # 補上nickname
SELECT a.id, (b.id%20)+1 as g, a.userid, b.nickname, a.CREATEon, a.ordernumber, a.price, a.payway, a.sellconfirm, a.CREATE_FROM, a.platform_type 
FROM plsport_playsport._order_data_check_a a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

CREATE TABLE plsport_playsport._order_data_check_b_1 engine = myisam # 補上nickname
SELECT a.id, (b.id%20)+1 as g, a.userid, b.nickname, a.CREATEon, a.ordernumber, a.price, a.payway, a.sellconfirm, a.CREATE_FROM, a.platform_type 
FROM plsport_playsport._order_data_check_b a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;


CREATE TABLE plsport_playsport._order_data_check_a_2 engine = myisam
SELECT id, g, (case when (g in (7,8,9,10,11,12)) then 'red' else 'blue' end) as paymethon, # 30%的人是用紅陽, 其它是藍新
       userid, nickname, date(CREATEon) as d, ordernumber, price, payway, sellconfirm, CREATE_FROM, platform_type 
FROM plsport_playsport._order_data_check_a_1
ORDER BY g;

CREATE TABLE plsport_playsport._order_data_check_b_2 engine = myisam
SELECT id, g, (case when (g in (7,8,9,10,11,12,13,14)) then 'red' else 'blue' end) as paymethon, # 40%的人是用紅陽, 其它是藍新
       userid, nickname, date(CREATEon) as d, ordernumber, price, payway, sellconfirm, CREATE_FROM, platform_type 
FROM plsport_playsport._order_data_check_b_1
ORDER BY g;


CREATE TABLE plsport_playsport._order_data_check_a_3 engine = myisam # 排除掉重覆在送出訂單前點擊的人
SELECT g, paymethon, userid, nickname, d, payway, sellconfirm
FROM plsport_playsport._order_data_check_a_2
GROUP BY g, paymethon, userid, nickname, d, payway, sellconfirm; # 一個人在同一天內用同一種方式結帳只算一次

CREATE TABLE plsport_playsport._order_data_check_b_3 engine = myisam # 排除掉重覆在送出訂單前點擊的人
SELECT g, paymethon, userid, nickname, d, payway, sellconfirm
FROM plsport_playsport._order_data_check_b_2
GROUP BY g, paymethon, userid, nickname, d, payway, sellconfirm; # 一個人在同一天內用同一種方式結帳只算一次


SELECT paymethon, sellconfirm, count(userid) as c # 可以用a/b testing計算機來算了
FROM plsport_playsport._order_data_check_a_3
GROUP BY paymethon, sellconfirm;

SELECT paymethon, sellconfirm, count(userid) as c # 可以用a/b testing計算機來算了
FROM plsport_playsport._order_data_check_b_3
GROUP BY paymethon, sellconfirm;


SELECT paymethon, payway, sum(price) as revenue
FROM plsport_playsport._order_data_check_b_2
WHERE sellconfirm = 1
GROUP BY paymethon, payway;

CREATE TABLE plsport_playsport._order_data_check_2_for_r engine = myisam 
SELECT userid, paymethon, sum(price) as revenue 
FROM plsport_playsport._order_data_check_2
WHERE sellconfirm = 1
GROUP BY userid, paymethon;

# 輸出txt給R使用
SELECT 'userid', 'm', 'r' UNION (
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_order_data_check_2_for_r.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._order_data_check_2_for_r);



# =================================================================================================
# 任務: 貼圖使用狀況研究 [新建] (福利班) 2015-02-13
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4451&projectId=11
# 目標：
#     1. 瞭解貼圖使用情形
#     2. 瞭解貼圖是否提高回文數量
# 請協助提供
#     1. 所有回文中，使用到新貼圖的比例
#     2. 從貼圖上線之後，回文中只有新貼圖，佔所有貼圖的比例；是否對照上線前，僅使用舊貼圖就回文的比例？
# 第一批上線時間 2014/10/27
# 第二批上線時間 2015/2/3
# 第三批上線時間 2015/4/10~6/1
# =================================================================================================
# 先匯入forumcontent
           
CREATE TABLE plsport_playsport._forumcontent engine = myisam
SELECT * 
FROM plsport_playsport.forumcontent
WHERE postdate between '2015-06-23 00:00:00' AND '2015-08-23 23:59:59';
# WHERE postdate between '2015-02-03 00:00:00' AND now();
# WHERE postdate between '2014-10-28 00:00:00' AND now();

CREATE TABLE plsport_playsport._forumcontent_1 engine = myisam
SELECT subjectid, userid, content, postdate 
FROM plsport_playsport._forumcontent;

CREATE TABLE plsport_playsport._forumcontent_2 engine = myisam
SELECT subjectid, userid, content, postdate, 
       (case when (locate('/includes/images/smiley/playsport01.png',content)>0) then 1 else 0 end) as p01,
       (case when (locate('/includes/images/smiley/playsport02.png',content)>0) then 1 else 0 end) as p02,
       (case when (locate('/includes/images/smiley/playsport03.png',content)>0) then 1 else 0 end) as p03,
       (case when (locate('/includes/images/smiley/playsport04.png',content)>0) then 1 else 0 end) as p04,
       (case when (locate('/includes/images/smiley/playsport05.png',content)>0) then 1 else 0 end) as p05,
       (case when (locate('/includes/images/smiley/playsport06.png',content)>0) then 1 else 0 end) as p06,
       (case when (locate('/includes/images/smiley/playsport07.png',content)>0) then 1 else 0 end) as p07,
       (case when (locate('/includes/images/smiley/playsport08.png',content)>0) then 1 else 0 end) as p08,
       (case when (locate('/includes/images/smiley/playsport09.png',content)>0) then 1 else 0 end) as p09,
       (case when (locate('/includes/images/smiley/playsport10.png',content)>0) then 1 else 0 end) as p10,
       (case when (locate('/includes/images/smiley/playsport11.png',content)>0) then 1 else 0 end) as p11,
       (case when (locate('/includes/images/smiley/playsport12.png',content)>0) then 1 else 0 end) as p12,
       (case when (locate('/includes/images/smiley/playsport13.png',content)>0) then 1 else 0 end) as p13,
       (case when (locate('/includes/images/smiley/playsport14.png',content)>0) then 1 else 0 end) as p14,
       (case when (locate('/includes/images/smiley/playsport15.png',content)>0) then 1 else 0 end) as p15,
       (case when (locate('/includes/images/smiley/playsport16.png',content)>0) then 1 else 0 end) as p16,
       (case when (locate('/includes/images/smiley/playsport17.png',content)>0) then 1 else 0 end) as p17,
       (case when (locate('/includes/images/smiley/playsport18.png',content)>0) then 1 else 0 end) as p18,
       (case when (locate('/includes/images/smiley/playsport19.png',content)>0) then 1 else 0 end) as p19,
       (case when (locate('/includes/images/smiley/playsport20.png',content)>0) then 1 else 0 end) as p20,
       (case when (locate('/includes/images/smiley/playsport21.png',content)>0) then 1 else 0 end) as p21,
       (case when (locate('/includes/images/smiley/playsport22.png',content)>0) then 1 else 0 end) as p22,
       (case when (locate('/includes/images/smiley/playsport23.png',content)>0) then 1 else 0 end) as p23,
       (case when (locate('/includes/images/smiley/playsport24.png',content)>0) then 1 else 0 end) as p24,
       (case when (locate('/includes/images/smiley/playsport25.png',content)>0) then 1 else 0 end) as p25,
       (case when (locate('/includes/images/smiley/playsport26.png',content)>0) then 1 else 0 end) as p26,
       (case when (locate('/includes/images/smiley/playsport27.png',content)>0) then 1 else 0 end) as p27,
       (case when (locate('/includes/images/smiley/playsport28.png',content)>0) then 1 else 0 end) as p28,
       (case when (locate('/includes/images/smiley/playsport29.png',content)>0) then 1 else 0 end) as p29,
       (case when (locate('/includes/images/smiley/playsport30.png',content)>0) then 1 else 0 end) as p30,       
       (case when (locate('/includes/images/smiley/playsport31.png',content)>0) then 1 else 0 end) as p31       
FROM plsport_playsport._forumcontent_1;

CREATE TABLE plsport_playsport._forumcontent_2_all_icon_stat engine = myisam
SELECT sum(p01), sum(p02), sum(p03), sum(p04), sum(p05), sum(p06), sum(p07), sum(p08), sum(p09), sum(p10), 
       sum(p11), sum(p12), sum(p13), sum(p14), sum(p15), sum(p16), sum(p17), sum(p18), sum(p19), sum(p20), 
       sum(p21), sum(p22), sum(p23), sum(p24), sum(p25), sum(p26), sum(p27), sum(p28), sum(p29), sum(p30),
       sum(p31)
FROM plsport_playsport._forumcontent_2;

CREATE TABLE plsport_playsport._forumcontent_1_1 engine = myisam
SELECT subjectid, userid, content, postdate, 
       (case when (locate('/includes/images/smiley/playsport',content)>0) then 1 else 0 end) as used_icon, 
       length(content) as word_count,
       (case when (locate('<p></p><img alt=',content)) then substr(content,1,16) else '' end) as pre,
       (case when (locate('width="150" />',content)) then substr(content,locate('width="150" />',content),length(content)) else '' end) as suf
FROM plsport_playsport._forumcontent_1;

CREATE TABLE plsport_playsport._forumcontent_1_2 engine = myisam
SELECT subjectid, userid, content, postdate, used_icon, word_count, 
       (case when (pre = '<p></p><img alt=') then 1 else 0 end) as pre, 
       (case when (suf = 'width="150" />') then 1 else 0 end) as suf
FROM plsport_playsport._forumcontent_1_1;

CREATE TABLE plsport_playsport._forumcontent_1_3 engine = myisam
SELECT * FROM plsport_playsport._forumcontent_1_2
WHERE used_icon = 1
AND pre = 1
AND suf = 1
AND word_count < 135;

SELECT a.d, count(a.subjectid) as c
FROM (
    SELECT date(postdate) as d, subjectid 
    FROM plsport_playsport._forumcontent_1_3) as a
GROUP BY a.d;


CREATE TABLE plsport_playsport._forumcontent_2_1 engine = myisam
SELECT subjectid, userid, content, postdate, 
       (case when (locate('/includes/images/smiley/',content)>0) then 1 else 0 end) as used_icon, 
       length(content) as word_count,
       (case when (locate('<p></p><img alt=',content)) then substr(content,1,16) else '' end) as pre,
       (case when (locate('width="19" />',content)) then substr(content,locate('width="19" />',content),length(content)) else '' end) as suf
FROM plsport_playsport._forumcontent_1;

CREATE TABLE plsport_playsport._forumcontent_2_2 engine = myisam
SELECT subjectid, userid, content, postdate, used_icon, word_count, 
       (case when (pre = '<p></p><img alt=') then 1 else 0 end) as pre, 
       (case when (suf = 'width="19" />') then 1 else 0 end) as suf
FROM plsport_playsport._forumcontent_2_1;

CREATE TABLE plsport_playsport._forumcontent_2_3 engine = myisam
SELECT * FROM plsport_playsport._forumcontent_2_2
WHERE used_icon = 1
AND pre = 1
AND suf = 1
AND word_count < 138;

SELECT a.d, count(a.subjectid) as c
FROM (
    SELECT date(postdate) as d, subjectid 
    FROM plsport_playsport._forumcontent_2_3) as a
GROUP BY a.d;


SELECT a.d, count(a.userid)
FROM (
    SELECT date(postdate) as d, userid 
    FROM plsport_playsport._forumcontent_1) as a
GROUP BY a.d;



# =================================================================================================
# 任務: [201412-H-1] 籃球比賽過程 - MVP測試名單 [新建] (阿達) 2015-02-24
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4274&projectId=11 
# 提供此任務 MVP測試名單
# 負責人：Eddy
# 時間：2/24(二)
#  
# 1. MVP測試名單
# 時間：近兩個月
# 條件：
#     a. NBA即時比分PV前50%
#     b. 問卷第二題回答需要或非常需要 (questionnaire_livescoreNbaViewImprovement_answer)
# 欄位：
#     a. 帳號
#     b. 暱稱
#     c. 近兩個月NBA即時比分pv及全站佔比
#     d. 問卷第二題答案
#     e. 手機、電腦使用佔比

# 和下面的任務合併
# 任務: [201412-F-8] 即時比分顯示隔日賽事數據 - 優化MVP測試名單 [新建]
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4321&projectId=11
# 1. MVP測試名單
# 時間：近兩個月
#  
# 條件：
# a. NBA即時比分PV前50%
# b. 問卷第三題回答喜歡或非常喜歡
# c. 問卷第二題回答需要或非常需要
# 欄位：
# a. 帳號
# b. 暱稱
# c. 近兩個月NBA即時比分pv及全站佔比
# d. 近兩個月點選NBA隔日的次數 (和上個任務獨立的條件)
# e. 問卷第二、三題答案 (questionnaire_livescoreTeamStat_answer)
# =================================================================================================

CREATE TABLE actionlog._livescore engine = myisam
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201411
WHERE userid <> '' AND uri LIKE '%livescore.php%';

INSERT IGNORE INTO actionlog._livescore
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201412
WHERE userid <> '' AND uri LIKE '%livescore.php%';

INSERT IGNORE INTO actionlog._livescore
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201501
WHERE userid <> '' AND uri LIKE '%livescore.php%';

INSERT IGNORE INTO actionlog._livescore
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201502
WHERE userid <> '' AND uri LIKE '%livescore.php%';

# 1. 轉換成PC和mobile
# 2. 近2個月
CREATE TABLE actionlog._livescore_1 engine = myisam
SELECT userid, uri, time, (case when (platform_type = 1) then 'PC' else 'mobile' end) as platform
FROM actionlog._livescore
WHERE time between subdate(now(),62) AND now();


CREATE TABLE actionlog._livescore_2 engine = myisam
SELECT userid, uri, (case when (locate('aid=',uri))=0 then 0 else substr(uri,locate('aid=',uri)+4,length(uri)) end) as m, time, platform 
FROM actionlog._livescore_1;

CREATE TABLE actionlog._livescore_3 engine = myisam
SELECT userid, uri, m, (case when (locate('&',m)=0) then m else substr(m,1,locate('&',m)-1) end) as aid, time, platform
FROM actionlog._livescore_2;

CREATE TABLE actionlog._livescore_4 engine = myisam
SELECT userid, uri, (case when (aid=0) then 3 else aid end) as aid, time, platform 
FROM actionlog._livescore_3;

# 看NBA即時比分的pv
CREATE TABLE plsport_playsport._nba_pv engine = myisam
SELECT userid, count(uri) as pv 
FROM actionlog._livescore_4
WHERE aid = 3
GROUP BY userid;

        # 計算看NBA即時比分的pv的percentile
        CREATE TABLE plsport_playsport._nba_pv_with_percentile engine = myisam
        SELECT userid, pv, round((cnt-rank+1)/cnt,2) as pv_percentile
        FROM (SELECT userid, pv, @curRank := @curRank + 1 AS rank
              FROM plsport_playsport._nba_pv, (SELECT @curRank := 0) r
              ORDER BY pv DESC) as dt,
             (SELECT count(distinct userid) as cnt FROM plsport_playsport._nba_pv) as ct;

        # 符合主條件的人
        CREATE TABLE plsport_playsport._nba_pv_with_percentile_1 engine = myisam
        SELECT * FROM plsport_playsport._nba_pv_with_percentile
        WHERE pv_percentile > 0.49;

# 最近一次登入
CREATE TABLE plsport_playsport._last_signin engine = myisam 
SELECT userid, max(signin_time) as last_signin
FROM plsport_playsport.member_signin_log_archive
GROUP BY userid;

# 即時比分的pv - 裝罝
CREATE TABLE plsport_playsport._device_usage engine = myisam 
SELECT b.userid, sum(b.pv_PC) as pv_PC, sum(b.pv_mobile) as pv_mobile
FROM (
    SELECT a.userid, (case when (a.platform='PC') then c else 0 end) as pv_PC, (case when (a.platform='mobile') then c else 0 end) as pv_mobile
    FROM (
        SELECT userid, platform, count(userid) as c
        FROM actionlog._livescore_4
        WHERE aid = 3
        GROUP BY userid, platform) as a) as b
GROUP BY b.userid;

        CREATE TABLE plsport_playsport._device_usage_1 engine = myisam # 即時比分的pv - 裝罝比例(使用這個)
        SELECT userid, pv_PC, pv_mobile, round(pv_PC/(pv_PC+pv_mobile),2) as PC_precent, round(pv_mobile/(pv_PC+pv_mobile),2) as Mobile_precent
        FROM plsport_playsport._device_usage;

# 計算點選隔日數據的人
CREATE TABLE actionlog._livescore_nextday_1 engine = myisam
SELECT a.userid, a.uri, a.time, substr(a.c,1,8) as nextday
FROM (
    SELECT userid, uri, time, (case when (locate('gamedate=', uri)=0) then "" else substr(uri,locate('gamedate=', uri)+9,length(uri)) end) as c
    FROM actionlog._livescore_4
    WHERE aid = 3) as a; # 只限看NBA

        CREATE TABLE actionlog._livescore_nextday_2 engine = myisam
        SELECT userid, uri, date(time) as today, str_to_date(nextday, '%Y%m%d') as nextday, datediff(str_to_date(nextday, '%Y%m%d'), date(time)) as s
        FROM actionlog._livescore_nextday_1
        WHERE nextday <> '';

        #抽出點選明天的人
        CREATE TABLE actionlog._livescore_nextday_3 engine = myisam
        SELECT * FROM actionlog._livescore_nextday_2
        WHERE s = 1;

        CREATE TABLE actionlog._livescore_nextday_4 engine = myisam
        SELECT userid, count(uri) as nextday_pv 
        FROM actionlog._livescore_nextday_3
        GROUP BY userid;

        CREATE TABLE plsport_playsport._livescore_nextday_list engine = myisam
        SELECT userid, nextday_pv, round((cnt-rank+1)/cnt,2) as nextday_pv_percentile
        FROM (SELECT userid, nextday_pv, @curRank := @curRank + 1 AS rank
              FROM actionlog._livescore_nextday_4, (SELECT @curRank := 0) r
              ORDER BY nextday_pv DESC) as dt,
             (SELECT count(distinct userid) as cnt FROM actionlog._livescore_nextday_4) as ct;


ALTER TABLE plsport_playsport._livescore_nextday_list convert to character SET utf8 collate utf8_general_ci;
ALTER TABLE plsport_playsport._device_usage_1 convert to character SET utf8 collate utf8_general_ci;
ALTER TABLE plsport_playsport._last_signin convert to character SET utf8 collate utf8_general_ci;
ALTER TABLE plsport_playsport._nba_pv_with_percentile_1 convert to character SET utf8 collate utf8_general_ci;

ALTER TABLE plsport_playsport._livescore_nextday_list ADD INDEX (`userid`);
ALTER TABLE plsport_playsport._device_usage_1 ADD INDEX (`userid`);
ALTER TABLE plsport_playsport._last_signin ADD INDEX (`userid`);
ALTER TABLE plsport_playsport._nba_pv_with_percentile_1 ADD INDEX (`userid`);

# 開始製作名單
CREATE TABLE plsport_playsport._list_1 engine = myisam # 加入nba即時比分pv
SELECT a.userid, b.nickname, a.pv as nba_pv, a.pv_percentile 
FROM plsport_playsport._nba_pv_with_percentile_1 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_2 engine = myisam # 加入點擊隔日賽事
SELECT a.userid, a.nickname, a.nba_pv, a.pv_percentile, b.nextday_pv, b.nextday_pv_percentile
FROM plsport_playsport._list_1 a LEFT JOIN plsport_playsport._livescore_nextday_list b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_3 engine = myisam # 加入使用裝置比例
SELECT a.userid, a.nickname, a.nba_pv, a.pv_percentile, a.nextday_pv, a.nextday_pv_percentile, b.pv_PC, b.pv_mobile, b.PC_precent, b.Mobile_precent
FROM plsport_playsport._list_2 a LEFT JOIN plsport_playsport._device_usage_1 b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_4 engine = myisam # 加入問券
SELECT a.userid, a.nickname, a.nba_pv, a.pv_percentile, a.nextday_pv, a.nextday_pv_percentile, a.pv_PC, a.pv_mobile, a.PC_precent, a.Mobile_precent, b.question02 as playbyplay
FROM plsport_playsport._list_3 a LEFT JOIN plsport_playsport.questionnaire_livescorenbaviewimprovement_answer b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_5 engine = myisam # 加入問券
SELECT a.userid, a.nickname, a.nba_pv, a.pv_percentile, a.nextday_pv, a.nextday_pv_percentile, a.pv_PC, a.pv_mobile, a.PC_precent, a.Mobile_precent, 
       a.playbyplay, b.question02 as q2, b.question03 as data_before_game
FROM plsport_playsport._list_4 a LEFT JOIN plsport_playsport.questionnaire_livescoreteamstat_answer b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_6 engine = myisam # 加入最後登入
SELECT a.userid, a.nickname, a.nba_pv, a.pv_percentile, a.nextday_pv, a.nextday_pv_percentile, a.pv_PC, a.pv_mobile, a.PC_precent, a.Mobile_precent, 
       a.playbyplay, a.data_before_game, date(b.last_signin) as last_signin
FROM plsport_playsport._list_5 a LEFT JOIN plsport_playsport._last_signin b on a.userid = b.userid;

# 名單完成
SELECT 'userid', 'nickname', 'nba即時比分pv', 'nba即時比分pv級距', '點選隔日賽事', '點選隔日賽事級距', '電腦', '手機', '電腦使用%', '手機使用%',
       '若在計分版上方顯示十秒前的比賽過程您覺得此功能是否需要', '是否喜歡開賽前顯示賽事數據', '最後登入' UNION (
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_list_6.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._list_6);



# =================================================================================================
# 任務: 討論區等級制度問券 [新建] (福利班) 2015-02-24
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4322&projectId=11
# 目的：詢問是否認同此制度，此制度是否能增加發文意願？
# 
# 總共四題
# 請看草稿
# http://www.playsport.cc/administration/questionnaire.php?action=previewQuestionnaire&id=201502111857119574
# 
# 預計受測者：D2 + D5
# 上線時間：2/25 ~ 2/28 
# =================================================================================================

CREATE TABLE actionlog._forum engine = myisam
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201411
WHERE uri LIKE '%/forum%';

INSERT IGNORE INTO actionlog._forum
SELECT userid, uri, time, platform_type FROM actionlog.action_201412
WHERE uri LIKE '%/forum%';

INSERT IGNORE INTO actionlog._forum
SELECT userid, uri, time, platform_type FROM actionlog.action_201501
WHERE uri LIKE '%/forum%';

INSERT IGNORE INTO actionlog._forum
SELECT userid, uri, time, platform_type FROM actionlog.action_201502
WHERE uri LIKE '%/forum%';

# 條件: 近2個月內
CREATE TABLE actionlog._forum_1 engine = myisam
SELECT * 
FROM actionlog._forum
WHERE userid <> ''
AND time between subdate(now(),62) AND now(); # 近2個月內的討論區pv數

CREATE TABLE actionlog._forum_2 engine = myisam
SELECT userid, count(uri) as pv 
FROM actionlog._forum_1
GROUP BY userid;

        CREATE TABLE plsport_playsport._forum_pv_with_percentile engine = myisam
        SELECT userid, pv, round((cnt-rank+1)/cnt,2) as pv_percentile
        FROM (SELECT userid, pv, @curRank := @curRank + 1 AS rank
              FROM actionlog._forum_2, (SELECT @curRank := 0) r
              ORDER BY pv DESC) as dt,
             (SELECT count(distinct userid) as cnt FROM actionlog._forum_2) as ct;

# 最近一次登入
CREATE TABLE plsport_playsport._last_signin engine = myisam 
SELECT userid, max(signin_time) as last_signin
FROM plsport_playsport.member_signin_log_archive
GROUP BY userid;

ALTER TABLE plsport_playsport._forum_pv_with_percentile convert to character SET utf8 collate utf8_general_ci;
ALTER TABLE plsport_playsport._forum_pv_with_percentile ADD INDEX (`userid`);

CREATE TABLE plsport_playsport._list_f_1 engine = myisam
SELECT a.userid, b.nickname, a.pv, a.pv_percentile 
FROM plsport_playsport._forum_pv_with_percentile a LEFT JOIN plsport_playsport.member b on a.userid = b.userid;

CREATE TABLE plsport_playsport._list_f_2 engine = myisam
SELECT a.userid, a.nickname, a.pv, a.pv_percentile, date(b.last_signin) as last_signin
FROM plsport_playsport._list_f_1 a LEFT JOIN plsport_playsport._last_signin b on a.userid = b.userid;

# 1. 統計近2個月的討論區pv數, 並取全站級距前55%的人
# 2. 需近1個月有登入過
CREATE TABLE plsport_playsport._list_f_3 engine = myisam
SELECT * 
FROM plsport_playsport._list_f_2
WHERE pv_percentile > 0.44
AND last_signin between subdate(now(),30) AND now();

SELECT 'userid' UNION (
SELECT userid
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_forum_level_questionnaire.csv'
fields terminated by ',' enclosed by '' lines terminated by '\r\n'
FROM plsport_playsport._list_f_3);



# 以下為問券的分析 2015-03-02(靜怡)
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4322&projectId=11

CREATE TABLE actionlog._forum engine = myisam
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201412
WHERE uri LIKE '%/forum%';
INSERT IGNORE INTO actionlog._forum
SELECT userid, uri, time, platform_type FROM actionlog.action_201501
WHERE uri LIKE '%/forum%';
INSERT IGNORE INTO actionlog._forum
SELECT userid, uri, time, platform_type FROM actionlog.action_201502
WHERE uri LIKE '%/forum%';
INSERT IGNORE INTO actionlog._forum
SELECT userid, uri, time, platform_type FROM actionlog.action_201503
WHERE uri LIKE '%/forum%';


# 條件: 近2個月內
CREATE TABLE actionlog._forum_1 engine = myisam
SELECT * 
FROM actionlog._forum
WHERE userid <> ''
AND time between subdate(now(),62) AND now(); # 近2個月內的討論區pv數

CREATE TABLE plsport_playsport._forum_post_count engine = myisam
SELECT postuser, count(subjectid) as post_count 
FROM plsport_playsport.forum
WHERE posttime between subdate(now(),62) AND now()
GROUP BY postuser;

CREATE TABLE plsport_playsport._forum_reply_count engine = myisam
SELECT userid, count(subjectid) as reply_count 
FROM plsport_playsport.forumcontent
WHERE postdate between subdate(now(),62) AND now()
GROUP BY userid;

CREATE TABLE plsport_playsport._forum_LIKE_count engine = myisam
SELECT userid, count(subject_id) as LIKE_count 
FROM plsport_playsport.forum_LIKE
WHERE CREATE_date between subdate(now(),62) AND now()
GROUP BY userid;

ALTER TABLE plsport_playsport._forum_post_count convert to character SET utf8 collate utf8_general_ci;
ALTER TABLE plsport_playsport._forum_reply_count convert to character SET utf8 collate utf8_general_ci;
ALTER TABLE plsport_playsport._forum_LIKE_count convert to character SET utf8 collate utf8_general_ci;

ALTER TABLE plsport_playsport._forum_post_count ADD INDEX (`postuser`);
ALTER TABLE plsport_playsport._forum_reply_count ADD INDEX (`userid`);
ALTER TABLE plsport_playsport._forum_LIKE_count ADD INDEX (`userid`);


CREATE TABLE plsport_playsport._forum_list_1 engine = myisam
SELECT a.userid, b.post_count
FROM plsport_playsport.member a LEFT JOIN plsport_playsport._forum_post_count b on a.userid = b.postuser;

CREATE TABLE plsport_playsport._forum_list_2 engine = myisam
SELECT a.userid, a.post_count, b.reply_count
FROM plsport_playsport._forum_list_1 a LEFT JOIN plsport_playsport._forum_reply_count b on a.userid = b.userid;

CREATE TABLE plsport_playsport._forum_list_3 engine = myisam
SELECT a.userid, a.post_count, a.reply_count, b.LIKE_count
FROM plsport_playsport._forum_list_2 a LEFT JOIN plsport_playsport._forum_LIKE_count b on a.userid = b.userid;


CREATE TABLE plsport_playsport._forum_list_4 engine = myisam
SELECT userid,  COALESCE(post_count, 0) as post_count, 
                COALESCE(reply_count, 0) as reply_count, 
                COALESCE(LIKE_count, 0) as LIKE_count 
FROM plsport_playsport._forum_list_3
WHERE userid <> '';

CREATE TABLE plsport_playsport._forum_list_5 engine = myisam
SELECT a.userid, a.s as score
FROM (
    SELECT userid, post_count, reply_count, LIKE_count, (post_count+reply_count+LIKE_count) as c, (post_count*7 + reply_count*3 + LIKE_count*0.2) as s
    FROM plsport_playsport._forum_list_4) as a
WHERE a.s > 0;

CREATE TABLE plsport_playsport._forum_list_6 engine = myisam
SELECT userid, score, round((cnt-rank+1)/cnt,2) as score_percentile
FROM (SELECT userid, score, @curRank := @curRank + 1 AS rank
      FROM plsport_playsport._forum_list_5, (SELECT @curRank := 0) r
      ORDER BY score DESC) as dt,
     (SELECT count(distinct userid) as cnt FROM plsport_playsport._forum_list_5) as ct;


CREATE TABLE plsport_playsport._forum_questionnaire engine = myisam
SELECT userid, `1423651483` as q1, `1423651637` as q2, `1423652084` as q3, `1424142973` as q4, `1424143026` as q5
FROM plsport_playsport.questionnaire_201502111857119574_answer
WHERE spend_minute > 0.29;

CREATE TABLE plsport_playsport._forum_list_7 engine = myisam
SELECT a.userid, a.q1, a.q2, a.q3, a.q4, a.q5, b.score, b.score_percentile
FROM plsport_playsport._forum_questionnaire a LEFT JOIN plsport_playsport._forum_list_6 b on a.userid = b.userid;


        update plsport_playsport._forum_list_7 SET q5 = replace(q5, ' ','');
        update plsport_playsport._forum_list_7 SET q5 = replace(q5, '　','');
        update plsport_playsport._forum_list_7 SET q5 = replace(q5, '\\','');
        update plsport_playsport._forum_list_7 SET q5 = replace(q5, ',','');
        update plsport_playsport._forum_list_7 SET q5 = replace(q5, ';','');
        update plsport_playsport._forum_list_7 SET q5 = replace(q5, '\n','');
        update plsport_playsport._forum_list_7 SET q5 = replace(q5, '\r','');
        update plsport_playsport._forum_list_7 SET q5 = replace(q5, '\t','');


SELECT 'userid', 'q1', 'q2', 'q3', 'q4', 'q5', 'score', 'p' UNION (
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/_forum_list_7.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._forum_list_7);



# =================================================================================================
# 任務: [201406-B-12]強化玩家搜尋-優化ABtesting [進行中] (靜怡) 2015-03-09
# 之前的完整版SQL寫在另一個檔案中 0_pending_usersearch.sql
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4043&projectId=11
# 說明
# 目的:了解增加預設玩家數量，是否讓使用者更喜歡
#  
# 內容
# - 測試時間:2/5~2/23
# - 報告時間:2/26
# - 觀察指標:1.預設玩家的點擊狀況。2.個人頁PV
# =================================================================================================

# 點擊分佈的檢查
CREATE TABLE actionlog._check_usersearch engine = myisam
SELECT userid, uri, time 
FROM actionlog.action_201502
WHERE uri LIKE '%rp=USE%'
AND userid <> ''
AND time between '2015-02-16 14:53:00' AND now();
# AND time between '2015-02-06 11:30:00' AND now();

insert ignore into actionlog._check_usersearch
SELECT userid, uri, time 
FROM actionlog.action_201503
WHERE uri LIKE '%rp=USE%'
AND userid <> ''
AND time between '2015-02-16 14:53:00' AND now();

CREATE TABLE actionlog._check_usersearch_1 engine = myisam
SELECT userid, uri, time, substr(uri,locate('&rp=',uri)+4,length(uri)) as p
FROM actionlog._check_usersearch;

CREATE TABLE actionlog._check_usersearch_2 engine = myisam
SELECT userid, uri, time, (case when (locate('&',p)=0) then p else substr(p,1,locate('&',p)-1) end) as p
FROM actionlog._check_usersearch_1;

    ALTER TABLE actionlog._check_usersearch_2 convert to character SET utf8 collate utf8_general_ci;

CREATE TABLE actionlog._check_usersearch_3 engine = myisam
SELECT c.g, (case when (c.g>10) then 'a' else 'b' end) as abtest, c.userid, c.uri, c.time, c.p
FROM (
    SELECT (b.id%20)+1 as g, a.userid, a.uri, a.time, a.p 
    FROM actionlog._check_usersearch_2 a LEFT JOIN plsport_playsport.member b on a.userid = b.userid) as c;

SELECT abtest, p, count(userid) as c 
FROM actionlog._check_usersearch_3
GROUP BY abtest, p;

CREATE TABLE actionlog._check_usersearch_4 engine = myisam
SELECT * 
FROM actionlog._check_usersearch_3
where substr(p,4,1) in (2,3);

# http://pm.playsport.cc/index.php/tasksComments?tasksId=3419&projectId=11
# 我們將這次a/b testing的目標都列出來:
# 
# 目標1:搜尋bar的使用率
# 目標2:從玩家搜尋點至個人頁的pv
# 目標3:進入玩家搜尋的pv
# 目標4:在玩家搜尋頁的所有pv
# 目標5:透過玩家搜尋購牌的金額
# 目標6:曾經透過玩家搜尋購牌的使用者在全站的消費金額

# (1)
CREATE TABLE actionlog._visit_usersearch engine = myisam
SELECT userid, uri, time 
FROM actionlog.action_201502
WHERE uri LIKE '%usersearch.php%'
AND userid <> ''
AND time between '2015-02-16 14:53:00' AND now();

insert ignore into actionlog._visit_usersearch
SELECT userid, uri, time 
FROM actionlog.action_201503
WHERE uri LIKE '%usersearch.php%'
AND userid <> ''
AND time between '2015-02-16 14:53:00' AND now();

    ALTER TABLE actionlog._visit_usersearch convert to character SET utf8 collate utf8_general_ci;

create table actionlog._visit_usersearch_1 engine = myisam
select c.g, (case when (c.g>10) then 'a' else 'b' end) as abtest, c.userid, c.uri, c.time, length(c.uri) as le
from (
    SELECT (b.id%20)+1 as g, a.userid, a.uri, a.time
    FROM actionlog._visit_usersearch a left join plsport_playsport.member b on a.userid = b.userid) as c;

select a.abtest, count(a.userid) as user_count
from (
    SELECT abtest, userid, count(uri) as c 
    FROM actionlog._visit_usersearch_1
    group by abtest, userid) as a
group by a.abtest;

select a.abtest, count(a.userid) as user_count
from (
    SELECT abtest, userid, count(uri) as c 
    FROM actionlog._visit_usersearch_1
    where le > 15
    group by abtest, userid) as a
group by a.abtest;

# 2340 > 1201
# 2383 > 1156

# (2)從玩家搜尋點至個人頁的pv
SELECT 'abtest', 'userid', 'pv' union (
SELECT abtest, userid, count(uri) as pv 
into outfile 'C:/Users/1-7_ASUS/Desktop/usersearch_2.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._check_usersearch_4
group by abtest, userid);

# (3)進入玩家搜尋的pv
SELECT 'abtest', 'userid', 'pv' union (
SELECT abtest, userid, count(uri) as pv 
into outfile 'C:/Users/1-7_ASUS/Desktop/usersearch_3.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._visit_usersearch_1
where le = 15
group by abtest, userid);

# (4)在玩家搜尋頁的所有pv
SELECT 'abtest', 'userid', 'pv' union (
SELECT abtest, userid, count(uri) as pv 
into outfile 'C:/Users/1-7_ASUS/Desktop/usersearch_4.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._visit_usersearch_1
group by abtest, userid);


# (5)來看消費金額-透過玩家搜尋購牌的金額
create table plsport_playsport._who_buy_predict_via_user_search engine = myisam
SELECT * 
FROM plsport_playsport._predict_buyer_with_cons
where substr(position,1,3) = 'USE'
and date(buy_date) between '2015-02-16 14:53:00' and now();

create table plsport_playsport._who_buy_predict_via_user_search_1 engine = myisam
select c.g, (case when (c.g > 10) then 'a' else 'b' end) as abtest, c.userid, c.buy_date, c.buy_price, c.position
from (
    SELECT (b.id%20)+1 as g, a.buyerid as userid, a.buy_date, a.buy_price, a.position
    FROM plsport_playsport._who_buy_predict_via_user_search a left join plsport_playsport.member b on a.buyerid = b.userid) as c;

create table plsport_playsport._who_buy_predict_via_user_search_2 engine = myisam
select a.g, a.abtest, a.userid, a.buy_date, a.buy_price, a.position, a.p
from (
    SELECT g, abtest, userid, buy_date, buy_price, position, concat(abtest,'_',position) as p
    FROM plsport_playsport._who_buy_predict_via_user_search_1) as a;

create table plsport_playsport._who_buy_predict_via_user_search_3 engine = myisam
SELECT * FROM plsport_playsport._who_buy_predict_via_user_search_2
where substr(p,6,1) in (2,3);

create table plsport_playsport._task_5_list_export engine = myisam
SELECT abtest, userid, sum(buy_price) as revenue 
FROM plsport_playsport._who_buy_predict_via_user_search_3
group by abtest, userid;

SELECT 'abtest', 'userid', 'revenue' union (
SELECT abtest, userid, sum(buy_price) as revenue 
into outfile 'C:/Users/1-7_ASUS/Desktop/usersearch_5.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._who_buy_predict_via_user_search_3
group by abtest, userid);


# (6)全站-曾經透過玩家搜尋購牌的使用者在全站的消費金額
create table plsport_playsport._who_buy_predict_via_user_search_all engine = myisam
SELECT * 
FROM plsport_playsport._predict_buyer_with_cons
where date(buy_date) between '2015-02-16 14:53:00' and now();


create table plsport_playsport._who_buy_predict_via_user_search_4 engine = myisam
SELECT buyerid as userid, buy_date as date, buy_price as price  
FROM plsport_playsport._who_buy_predict_via_user_search_all
where buyerid in (SELECT userid 
                  FROM plsport_playsport._task_5_list_export
                  group by userid);

create table plsport_playsport._who_buy_predict_via_user_search_5 engine = myisam
select c.g, (case when (c.g > 10) then 'a' else 'b' end) as abtest, c.userid, c.date, c.price
from (
    SELECT (b.id%20)+1 as g, a.userid as userid, a.date, a.price
    FROM plsport_playsport._who_buy_predict_via_user_search_4 a left join plsport_playsport.member b on a.userid = b.userid) as c;

create table plsport_playsport._task_6_list_export engine = myisam
SELECT abtest, userid, sum(price) as c 
FROM plsport_playsport._who_buy_predict_via_user_search_5
group by abtest, userid;

SELECT 'abtest', 'userid', 'revenue' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/usersearch_6.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._task_6_list_export);


# 補充: 使用者是否常在點擊第3列

create table actionlog._check_usersearch_5 engine = myisam
SELECT abtest, userid, uri, time, p, (case when (locate('ucp=',uri)>0) then substr(uri,locate('ucp=',uri)+4,length(uri)) else '' end) as ucp
FROM actionlog._check_usersearch_4;

create table actionlog._check_usersearch_6 engine = myisam
SELECT abtest, p, ucp, count(uri) as c 
FROM actionlog._check_usersearch_5
group by abtest, p, ucp;



# =================================================================================================
# 任務: [201502-C-2]優化手機版購買噱幣頁-付款方式使用比列 [新建] (靜怡) 2015-03-06
# 說明
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4299&projectId=11
# 目的:了解站上付款方式的使用比列
# 內容
# - (1)站上各付款方式的使用率與成功率
# - (2)快速結帳與(3)優惠儲值使用率與成功率
# - 需求裝置:電腦與手機
# - 統計區間:近一年
# - 提交時間:3/5
# =================================================================================================

create table plsport_playsport._order_data_1 engine = myisam
SELECT userid, createon, ordernumber, price, payway, sellconfirm, create_from,
       (case when (platform_type<2) then 'pc' else 'mobile' end) as pf
FROM plsport_playsport.order_data
where createon between subdate(now(),369) AND now()
order by userid;

create table plsport_playsport._order_data_2 engine = myisam
SELECT userid, createon, substr(createon,1,13) as h, ordernumber, price, payway, sellconfirm, create_from, pf 
FROM plsport_playsport._order_data_1;

ALTER TABLE plsport_playsport._order_data_2 ADD INDEX (`userid`, `h`, `price`, `payway`, `sellconfirm`, `create_from`);

# 需要排除掉重覆點擊(產生訂單編號)的記錄, 會比較精準
create table plsport_playsport._order_data_3 engine = myisam
SELECT userid, max(createon) as createon, h, ordernumber, price, payway, sellconfirm, create_from, pf 
FROM plsport_playsport._order_data_2
group by userid, h, price, payway, sellconfirm, create_from ;

SELECT * 
FROM plsport_playsport._order_data_3;

# 可匯至EXCEL
SELECT 'userid', 'createon', 'h', 'orderno', 'price', 'payway', 'sellconfirm', 'createfrom', 'pf' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_order_data_3.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._order_data_3);


# Thu, Mar 12, 2015 at 11:18 AM
# EDDY
# 
# 麻煩幫我查詢MYCARD點數在手機上的使用率
# 只要針對手機就好
# 這不急你再抽空幫我查一下
# 謝謝


create table plsport_playsport._order_data engine = myisam
SELECT id, userid, createon, ordernumber, price, payway, sellconfirm, create_from, platform_type
FROM plsport_playsport.order_data
where createon between subdate(now(),369) AND now();

create table plsport_playsport._orders_pcash_other engine = myisam
SELECT * FROM plsport_playsport.orders_pcash_other
where date between subdate(now(),369) AND now();


ALTER TABLE plsport_playsport._order_data ADD INDEX (`id`);
ALTER TABLE plsport_playsport._orders_pcash_other ADD INDEX (`id_order_data`);

create table plsport_playsport._order_data_1 engine = myisam
SELECT a.id, a.userid, a.createon, a.ordernumber, a.price, a.payway, a.sellconfirm, a.create_from, a.platform_type, b.paymenttype, b.final_paymenttype
FROM plsport_playsport._order_data a left join plsport_playsport._orders_pcash_other b on a.id = b.id_order_data;


create table plsport_playsport._order_data_2 engine = myisam
select *
from (
    SELECT id, userid, createon, ordernumber, price, payway, sellconfirm, create_from, 
           (case when (platform_type<2) then 'pc' else 'mobile' end) as p, paymenttype, final_paymenttype 
    FROM plsport_playsport._order_data_1) as a
where a.p = 'mobile'
and sellconfirm = 1;


SELECT payway, count(userid) as c 
FROM plsport_playsport._order_data_2
where substr(final_paymenttype,1,3) = 'MFS'
group by payway;



# =================================================================================================
# 任務: 快速結帳開關使用狀況 [新建] (靜怡) 2015-03-10
# 目的
# 
# 知選擇關閉快速結帳的使用狀況
# 
# 內容
# - 統計區間:近三個月
# - 對象:有看過快速結帳的使用者
# - 需求:關閉快速結帳的比列
# =================================================================================================

create table plsport_playsport.quick_order_switch_1_open engine = myisam
SELECT * 
FROM plsport_playsport.quick_order_switch
where create_time between '2014-12-01 00:00:00' AND now()
order by id desc;

SELECT count(userid) 
FROM plsport_playsport.quick_order_switch_1_open;

select count(a.userid) as c
from (
    SELECT userid,off_time
    FROM plsport_playsport.quick_order_switch_1_open
    group by userid) as a;

select count(a.userid) as c
from (
    SELECT userid,off_time
    FROM plsport_playsport.quick_order_switch_1_open
    where off_time is not null
    group by userid) as a;


# =================================================================================================
# 任務: [201408-A-13]開發回文推功能-發文推比狀況了解 [新建] (靜怡) 2015-03-11
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4349&projectId=11
# 說明
# 目的:1.了解發文推比現況 2.找出發文推比下降原因
# 
# 內容
# - 針對使用裝置、聯盟與文章類別進行了解分析
# - 使用裝置:發文推介面在電腦與手機點擊狀況
# - 文章分類:發文推介面在分析、感謝 、Live、亮單 、新聞等類別點擊狀況
# - 聯盟:發文推介面在各聯盟文章點擊狀況
# - 統計時間區段由DEEY自行設定
# - 報告時間:3/11
# =================================================================================================

# 先匯入以下tables:
# forum
# forum_like
# member
# member_signin_log_archive

create table plsport_playsport._member_signin engine = myisam
SELECT userid, date(signin_time) as d 
FROM plsport_playsport.member_signin_log_archive
where signin_time between '2014-01-01 00:00:00' and now();

create table plsport_playsport._forum engine = myisam
SELECT subjectid, allianceid, gametype, postuser, date(posttime) as d, replycount, pushcount 
FROM plsport_playsport.forum
where posttime between '2014-01-01 00:00:00' and now();

create table plsport_playsport._forum_like engine = myisam
SELECT subject_id, userid, date(create_date) as d
FROM plsport_playsport.forum_like
where create_date between '2014-01-01 00:00:00' and now();


create table plsport_playsport._member_signin_1 engine = myisam
SELECT userid, d, count(userid) as c 
FROM plsport_playsport._member_signin
group by userid, d;

create table plsport_playsport._member_signin_2 engine = myisam
SELECT d, count(userid) as user_count 
FROM plsport_playsport._member_signin_1
group by d;

create table plsport_playsport._forum_like_1 engine = myisam
SELECT d, userid, count(subject_id) as c 
FROM plsport_playsport._forum_like
group by d, userid;

create table plsport_playsport._forum_like_2 engine = myisam
SELECT d, count(userid) as like_user_count 
FROM plsport_playsport._forum_like_1
group by d;

create table plsport_playsport._forum_1 engine = myisam
SELECT d, postuser, count(subjectid) as c 
FROM plsport_playsport._forum
group by d, postuser;

create table plsport_playsport._forum_2 engine = myisam
SELECT d, count(postuser) as post_user_count 
FROM plsport_playsport._forum_1
group by d;

create table plsport_playsport._main_check_table engine = myisam
select c.d, c.user_count, c.post_user_count, d.like_user_count
from (
    SELECT a.d, a.user_count, b.post_user_count
    FROM plsport_playsport._member_signin_2 a left join plsport_playsport._forum_2 b on a.d = b.d) as c
    left join plsport_playsport._forum_like_2 as d on c.d = d.d;

create table plsport_playsport._main_check engine = myisam
select a.d, a.post, a.reply_count, a.push_count, round((a.reply_count/a.post),2) as r_r, round((a.push_count/a.post),2) as p_r
from (
    SELECT d, count(subjectid) as post, sum(replycount) as reply_count, sum(pushcount) as push_count 
    FROM plsport_playsport._forum
    group by d) as a;
    
        # 以聯盟來區分
        create table plsport_playsport._main_check_mlb engine = myisam
        select a.d, a.post, a.reply_count, a.push_count, round((a.reply_count/a.post),2) as r_r, round((a.push_count/a.post),2) as p_r
        from (
            SELECT d, count(subjectid) as post, sum(replycount) as reply_count, sum(pushcount) as push_count 
            FROM plsport_playsport._forum
            where allianceid = 1
            group by d) as a;
            
        create table plsport_playsport._main_check_nba engine = myisam
        select a.d, a.post, a.reply_count, a.push_count, round((a.reply_count/a.post),2) as r_r, round((a.push_count/a.post),2) as p_r
        from (
            SELECT d, count(subjectid) as post, sum(replycount) as reply_count, sum(pushcount) as push_count 
            FROM plsport_playsport._forum
            where allianceid = 3
            group by d) as a;
            
        create table plsport_playsport._main_check_kba engine = myisam
        select a.d, a.post, a.reply_count, a.push_count, round((a.reply_count/a.post),2) as r_r, round((a.push_count/a.post),2) as p_r
        from (
            SELECT d, count(subjectid) as post, sum(replycount) as reply_count, sum(pushcount) as push_count 
            FROM plsport_playsport._forum
            where allianceid = 92
            group by d) as a;    
    
        # 以聯盟來區分(總表), 因為有些日期不一定所有聯盟都有, 所以要join在一起
        select e.d, e.all_push_ratio, e.nba, e.mlb, f.p_r as kba
        from (
            select c.d, c.all_push_ratio, c.nba, d.p_r as mlb
            from (
                SELECT a.d, a.p_r as all_push_ratio, b.p_r as nba
                FROM plsport_playsport._main_check a left join plsport_playsport._main_check_nba b on a.d = b.d) as c
                left join plsport_playsport._main_check_mlb as d on c.d = d.d) as e
            left join plsport_playsport._main_check_kba as f on e.d = f.d
        order by e.d;
            

        create table plsport_playsport._main_check_all_ana_post engine = myisam
        select a.d, a.post, a.reply_count, a.push_count, round((a.reply_count/a.post),2) as r_r, round((a.push_count/a.post),2) as p_r
        from (
            SELECT d, count(subjectid) as post, sum(replycount) as reply_count, sum(pushcount) as push_count 
            FROM plsport_playsport._forum
            where gametype = 1
            group by d) as a; 

        create table plsport_playsport._main_check_nba_ana_post engine = myisam
        select a.d, a.post, a.reply_count, a.push_count, round((a.reply_count/a.post),2) as r_r, round((a.push_count/a.post),2) as p_r
        from (
            SELECT d, count(subjectid) as post, sum(replycount) as reply_count, sum(pushcount) as push_count 
            FROM plsport_playsport._forum
            where allianceid = 3
            and gametype = 1
            group by d) as a; 
            
        create table plsport_playsport._main_check_mlb_ana_post engine = myisam
        select a.d, a.post, a.reply_count, a.push_count, round((a.reply_count/a.post),2) as r_r, round((a.push_count/a.post),2) as p_r
        from (
            SELECT d, count(subjectid) as post, sum(replycount) as reply_count, sum(pushcount) as push_count 
            FROM plsport_playsport._forum
            where allianceid = 1
            and gametype = 1
            group by d) as a;
            
        create table plsport_playsport._main_check_kba_ana_post engine = myisam
        select a.d, a.post, a.reply_count, a.push_count, round((a.reply_count/a.post),2) as r_r, round((a.push_count/a.post),2) as p_r
        from (
            SELECT d, count(subjectid) as post, sum(replycount) as reply_count, sum(pushcount) as push_count 
            FROM plsport_playsport._forum
            where allianceid = 92
            and gametype = 1
            group by d) as a;              
            
        select e.d, e.all_push_ratio, e.nba, e.mlb, f.p_r as kba
        from (
            select c.d, c.all_push_ratio, c.nba, d.p_r as mlb
            from (
                SELECT a.d, a.p_r as all_push_ratio, b.p_r as nba
                FROM plsport_playsport._main_check_all_ana_post a left join plsport_playsport._main_check_nba_ana_post b on a.d = b.d) as c
                left join plsport_playsport._main_check_mlb_ana_post as d on c.d = d.d) as e
            left join plsport_playsport._main_check_kba_ana_post as f on e.d = f.d
        order by e.d;            
            
# 以裝置來區分, 但因為資料較大, 處理時間較久, 所以只先抽出看2月份的就好
create table plsport_playsport._forumdetail_201502 engine = myisam
SELECT userid, uri, substr(time,1,15) as t, (case when (platform_type<2) then 'pc' else 'mobile' end) as p 
FROM actionlog.action_201502
where userid <> ''
and uri like '%forumdetail.php%';

create table plsport_playsport._forumdetail_201402 engine = myisam
SELECT userid, uri, substr(time,1,15) as t, (case when (platform_type<2) then 'pc' else 'mobile' end) as p 
FROM actionlog.action_201402
where userid <> ''
and uri like '%forumdetail.php%';

create table plsport_playsport._forumdetail_201502_a engine = myisam
SELECT userid, t, p, count(uri) as c 
FROM plsport_playsport._forumdetail_201502
group by userid, t, p;

create table plsport_playsport._forumdetail_201402_a engine = myisam
SELECT userid, t, p, count(uri) as c 
FROM plsport_playsport._forumdetail_201402
group by userid, t, p;

create table plsport_playsport._forum_like_201502 engine = myisam
SELECT subject_id, userid, substr(create_date,1,15) as t
FROM plsport_playsport.forum_like
where substr(create_date,1,7) = '2015-02';

create table plsport_playsport._forum_like_201402 engine = myisam
SELECT subject_id, userid, substr(create_date,1,15) as t
FROM plsport_playsport.forum_like
where substr(create_date,1,7) = '2014-02';

        ALTER TABLE plsport_playsport._forumdetail_201502_a ADD INDEX (`userid`,`t`);
        ALTER TABLE plsport_playsport._forumdetail_201402_a ADD INDEX (`userid`,`t`);
        ALTER TABLE plsport_playsport._forum_like_201502 ADD INDEX (`userid`,`t`);
        ALTER TABLE plsport_playsport._forum_like_201402 ADD INDEX (`userid`,`t`);
        ALTER TABLE plsport_playsport._forumdetail_201502_a convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE plsport_playsport._forumdetail_201402_a convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE plsport_playsport._forum_like_201502 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE plsport_playsport._forum_like_201402 convert to character set utf8 collate utf8_general_ci;

create table plsport_playsport._forum_like_201502_with_device engine = myisam
SELECT  a.subject_id, a.userid, a.t, b.p
FROM plsport_playsport._forum_like_201502 a left join plsport_playsport._forumdetail_201502_a b on a.userid = b.userid and a.t = b.t;

create table plsport_playsport._forum_like_201402_with_device engine = myisam
SELECT  a.subject_id, a.userid, a.t, b.p
FROM plsport_playsport._forum_like_201402 a left join plsport_playsport._forumdetail_201402_a b on a.userid = b.userid and a.t = b.t;

create table plsport_playsport._forum_like_201502_with_device_1 engine = myisam
select a.userid, a.t, a.p, count(userid) as c
from (
    SELECT userid, substr(t,1,10) as t, p 
    FROM plsport_playsport._forum_like_201502_with_device
    where p is not null) as a
group by a.userid, a.t, a.p;

create table plsport_playsport._forum_like_201402_with_device_1 engine = myisam
select a.userid, a.t, a.p, count(userid) as c
from (
    SELECT userid, substr(t,1,10) as t, p 
    FROM plsport_playsport._forum_like_201402_with_device
    where p is not null) as a
group by a.userid, a.t, a.p;

# 完成
SELECT t, p, count(userid) as user_count 
FROM plsport_playsport._forum_like_201502_with_device_1
group by t, p;

SELECT t, p, count(userid) as user_count 
FROM plsport_playsport._forum_like_201402_with_device_1
group by t, p;


# =================================================================================================
# 任務: [201408-A-17]開發回文推功能-第四次發文推樣式ABtesting [新建] (靜怡) 2015-05-06
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4654&projectId=11
# 說明
# 了解發文上方的推按鍵，是否會對推數有影響
# 
# 內容
# - 測試時間：5/5~6/5
# - 設定測試組別
# - 觀察指標：發文推數
# - 報告時間：6/10
# =================================================================================================

# a/b testing 測試名單(a版): (userid%20)+1 in (11,12,13,14,15,16,17,18,19,20)
# a 版: 上下都有推版
# b 版: 只有下面有推版
# 按紐送出的event設定如下:
# 資料表event
# a 版:  上面pushit_bottom_top_a, 下面pushit_bottom_low_a
# b 版:  下面pushit_bottom_low_b

# 下面是用來檢查分組狀態的部分
# 先匯入event
create table plsport_playsport._events engine = myisam
SELECT * FROM plsport_playsport.events
where name like '%pushit_bottom%'
and time between '2015-07-07 11:26:00' and now() 
order by id desc;

create table plsport_playsport._events1 engine = myisam
SELECT (case when ((b.id%20)+1>10) then 'a' else 'b' end) as abtest , a.userid, a.name, substr(name,length(name)-4,length(name)) as c, a.time, a.platform_type
FROM plsport_playsport._events a left join plsport_playsport.member b on a.userid = b.userid;

update plsport_playsport._events1 set platform_type = 1 where platform_type = 3;



SELECT abtest, c, count(userid) as d
FROM plsport_playsport._events1
group by abtest, c;

# TO EDDY 2015-07-07 11:36
# 發文推ABtssting已於今日重新上縣
# 主文內容也一併做修正
# 
# - 測試時間：7/7~8/7
# - 設定測試組別
# - 觀察指標：發文推數
# - 報告時間：8/11

create table plsport_playsport._events2 engine = myisam
select a.abtest, a.userid, a.name, a.c, a.time, a.platform_type
from (
    SELECT abtest, userid, name, c, time, platform_type, concat(abtest,c) as q
    FROM plsport_playsport._events1) as a
where a.q not in ('blow_a', 'btop_a');

create table plsport_playsport._events3 engine = myisam
SELECT abtest, userid, count(userid) as c
FROM plsport_playsport._events2
group by abtest, userid;

SELECT 'abtest', 'userid', 'c' union (
SELECT *
into outfile 'C:/proc/r/abtest/_events3.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._events3);

create table plsport_playsport._events3_by_devices engine = myisam
SELECT abtest, userid, platform_type, count(userid) as c
FROM plsport_playsport._events2
group by abtest, userid, platform_type;

SELECT 'abtest', 'userid', 'platform_type', 'c' union (
SELECT *
into outfile 'C:/proc/r/abtest/_events3_by_devices.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._events3_by_devices);

create table plsport_playsport._log engine = myisam
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201507
where time between '2015-07-07 11:26:00' and now()
and userid <> '' and uri like '%forumdetail.php%';
insert ignore into plsport_playsport._log
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201508
where time between '2015-07-07 11:26:00' and now()
and userid <> '' and uri like '%forumdetail.php%';


update plsport_playsport._log set platform_type = 1 where platform_type = 3;

create table plsport_playsport._log_1 engine = myisam
SELECT userid,  count(uri) as pv
FROM plsport_playsport._log
group by userid;

create table plsport_playsport._log_1_by_devices engine = myisam
SELECT userid, platform_type, count(uri) as pv
FROM plsport_playsport._log
group by userid, platform_type;

        ALTER TABLE plsport_playsport._log_1 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE plsport_playsport._log_1_by_devices convert to character set utf8 collate utf8_general_ci;

create table plsport_playsport._log_2 engine = myisam
SELECT (case when ((b.id%20)+1>10) then 'a' else 'b' end) as abtest, a.userid, a.pv 
FROM plsport_playsport._log_1 a left join plsport_playsport.member b on a.userid = b.userid; 

create table plsport_playsport._log_2_by_devices engine = myisam
SELECT (case when ((b.id%20)+1>10) then 'a' else 'b' end) as abtest, a.userid, a.platform_type, a.pv 
FROM plsport_playsport._log_1_by_devices a left join plsport_playsport.member b on a.userid = b.userid; 



SELECT abtest, count(userid) as c 
FROM plsport_playsport._log_2
group by abtest;

# a	8141 > 2503 31% *
# b	8142 > 2323 29%

SELECT abtest, platform_type, count(userid) as c 
FROM plsport_playsport._log_2_by_devices
group by abtest, platform_type;

# a	1	5741 > 1755 31% *
# b	1	5596 > 1584 28%

# a	2	5344 > 1339 25% * 
# b	2	5321 > 1258 24% 








# =================================================================================================
# 任務: [201412-F-10] 即時比分顯示隔日賽事數據 - APP prototype 測試名單 [新建] (阿達) 2015-03-19
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4434&projectId=11
# 請提供訪談名單，供文婷約訪
# 時間：3/20 (五)
# 負責人：Eddy
# 
# 訪談名單
# 1. 統計區間
#         近三個月
# 2. 篩選條件
#         有點選過 iOS或Android即時比分APP版標廣告的使用者
# 3. 資料欄位
#         基本資料 
#         帳號
#         暱稱
#         手機系統( Android or iOS)
#         手機/電腦使用比率
#         居住地
# APP
#         APP版標點選天數
#         APP版標點選次數
# 網頁
#         點選即時比分NBA 隔日天數
#         點選賽事數據天數(games_data.php)
#         點選預測比例天數(問阿達)
# =================================================================================================
# 匯入(1)app_action_log (2)member
# 有點選過 iOS或Android即時比分APP版標廣告的使用者, 應該不是從app_action_log來捉, 而是從action_log的追蹤代碼來捉

create table actionlog._from_app engine = myisam
SELECT userid, uri, time, platform_type
FROM actionlog.action_201412
where userid <> '' and (uri like '%rp=MS%' or uri like '%rp=MF%');
insert ignore into actionlog._from_app
SELECT userid, uri, time, platform_type
FROM actionlog.action_201501
where userid <> '' and (uri like '%rp=MS%' or uri like '%rp=MF%');
insert ignore into actionlog._from_app
SELECT userid, uri, time, platform_type
FROM actionlog.action_201502
where userid <> '' and (uri like '%rp=MS%' or uri like '%rp=MF%');
insert ignore into actionlog._from_app
SELECT userid, uri, time, platform_type
FROM actionlog.action_201503
where userid <> '' and (uri like '%rp=MS%' or uri like '%rp=MF%');

create table actionlog._gamedata engine = myisam
SELECT userid, uri, time, platform_type
FROM actionlog.action_201412
where userid <> '' and uri like '%games_data.php%';
insert ignore into actionlog._gamedata
SELECT userid, uri, time, platform_type
FROM actionlog.action_201501
where userid <> '' and uri like '%games_data.php%';
insert ignore into actionlog._gamedata
SELECT userid, uri, time, platform_type
FROM actionlog.action_201502
where userid <> '' and uri like '%games_data.php%';
insert ignore into actionlog._gamedata
SELECT userid, uri, time, platform_type
FROM actionlog.action_201503
where userid <> '' and uri like '%games_data.php%';

create table actionlog._predictscale engine = myisam
SELECT userid, uri, time, platform_type
FROM actionlog.action_201412
where userid <> '' and uri like '%predictgame.php?action=scale%';
insert ignore into actionlog._predictscale
SELECT userid, uri, time, platform_type
FROM actionlog.action_201501
where userid <> '' and uri like '%predictgame.php?action=scale%';
insert ignore into actionlog._predictscale
SELECT userid, uri, time, platform_type
FROM actionlog.action_201502
where userid <> '' and uri like '%predictgame.php?action=scale%';
insert ignore into actionlog._predictscale
SELECT userid, uri, time, platform_type
FROM actionlog.action_201503
where userid <> '' and uri like '%predictgame.php?action=scale%';

create table actionlog._livescore engine = myisam
SELECT userid, uri, time, platform_type
FROM actionlog.action_201412
where userid <> '' and uri like '%livescore.php%';
insert ignore into actionlog._livescore
SELECT userid, uri, time, platform_type
FROM actionlog.action_201501
where userid <> '' and uri like '%livescore.php%';
insert ignore into actionlog._livescore
SELECT userid, uri, time, platform_type
FROM actionlog.action_201502
where userid <> '' and uri like '%livescore.php%';
insert ignore into actionlog._livescore
SELECT userid, uri, time, platform_type
FROM actionlog.action_201503
where userid <> '' and uri like '%livescore.php%';

create table actionlog._from_app_1 engine = myisam
SELECT userid, uri, time, (case when (platform_type<2) then 'pc' else 'mobile' end) as p
FROM actionlog._from_app
where time between subdate(now(),93) and now();

create table actionlog._from_app_2 engine = myisam
SELECT userid, uri, time, p, substr(uri,locate('rp=',uri)+3,length(uri)) as rp 
FROM actionlog._from_app_1;

        SELECT rp, count(userid) as c 
        FROM actionlog._from_app_2
        group by rp;

create table actionlog._from_app_3 engine = myisam
SELECT userid, uri, time, date(time) as d, p, rp, (case when (substr(rp,1,2)='MS') then 'livescore' else 'forum' end) as app
FROM actionlog._from_app_2;

create table actionlog._from_app_4 engine = myisam
SELECT userid, uri, time, d, p, rp, app, (case when (substr(rp,3,1)='A') then 'android' else 'ios' end) as os 
FROM actionlog._from_app_3;

        SELECT rp, app, os, count(userid) as c 
        FROM actionlog._from_app_4
        group by rp, app, os;

create table actionlog._from_app_5 engine = myisam
SELECT userid, d, os, count(uri) as click 
FROM actionlog._from_app_4
where app = 'livescore'
group by userid, d, os;

create table actionlog._from_app_5_1 engine = myisam
select a.userid, sum(a.click_and) as click_and, sum(a.click_ios) as click_ios
from (
    SELECT userid, (case when (os='android') then click else 0 end) as click_and, # 點擊版標android
                   (case when (os='ios') then click else 0 end) as click_ios      # 點擊版標ios
    FROM actionlog._from_app_5) as a
group by a.userid;

create table actionlog._from_app_5_2 engine = myisam
select c.userid, sum(c.days_and) as days_and, sum(c.days_ios) as days_ios
from (
    select b.userid, (case when (b.os='android') then b.c else 0 end) as days_and,# 點擊版標天數android 
                     (case when (b.os='ios') then b.c else 0 end) as days_ios     # 點擊版標天數ios
    from (
        select a.userid, a.os, count(a.d) as c
        from (
            SELECT userid, d, os, count(userid) as c 
            FROM actionlog._from_app_5
            group by userid, d, os) as a
        group by a.userid, a.os) as b) as c
group by c.userid;

create table actionlog._from_app_6 engine = myisam
SELECT a.userid, a.click_and, a.click_ios, b.days_and, b.days_ios
FROM actionlog._from_app_5_1 a left join actionlog._from_app_5_2 b on a.userid = b.userid;


# (1)點選即時比分NBA 隔日天數
CREATE TABLE actionlog._livescore_1 engine = myisam
SELECT a.userid, a.uri, a.time, (case when (locate('&',a.t)=0) then a.t else substr(a.t,1,locate('&',a.t)-1) end) as p
FROM (
    SELECT userid, uri, time, (case when (locate('aid=',uri)=0) then 3 else substr(uri, locate('aid=',uri)+4, length(uri)) end) as t
    FROM actionlog._livescore) as a;

CREATE TABLE actionlog._livescore_2 engine = myisam
SELECT * 
FROM actionlog._livescore_1
WHERE length(p) in (1,2)
AND p = 3; # allianceid = 3 NBA

CREATE TABLE actionlog._livescore_nextday_1 engine = myisam
SELECT a.userid, a.uri, a.time, a.p, substr(a.c,1,8) as nextday
FROM (
    SELECT userid, uri, time, p, (case when (locate('gamedate=', uri)=0) then "" else substr(uri,locate('gamedate=', uri)+9,length(uri)) end) as c
    FROM actionlog._livescore_2) as a;

CREATE TABLE actionlog._livescore_nextday_2 engine = myisam
SELECT userid, uri, date(time) as today, str_to_date(nextday, '%Y%m%d') as nextday, p, datediff(str_to_date(nextday, '%Y%m%d'), date(time)) as s
FROM actionlog._livescore_nextday_1
WHERE nextday <> '';
        
        # 看看大家都是點那幾天
        SELECT s, count(userid) 
        FROM actionlog._livescore_nextday_2
        GROUP BY s;

#抽出點選明天的人
CREATE TABLE actionlog._livescore_nextday_3 engine = myisam
SELECT * FROM actionlog._livescore_nextday_2
WHERE s = 1;

CREATE TABLE actionlog._livescore_nextday_4 engine = myisam
select a.userid, count(a.today) as click_nextday
from (
    SELECT userid, today, count(uri) as c 
    FROM actionlog._livescore_nextday_3
    where today between subdate(now(),94) and now() 
    group by userid, today) as a
group by a.userid;


# (2)點選賽事數據天數(games_data.php)
create table actionlog._gamedata_1 engine = myisam
select a.userid, a.d, count(a.uri) as c
from (
    SELECT userid, uri, date(time) as d, platform_type 
    FROM actionlog._gamedata) as a
group by a.userid, a.d;

create table actionlog._gamedata_2 engine = myisam
SELECT userid, count(d) as click_gamedata 
FROM actionlog._gamedata_1
where d between subdate(now(),94) and now() 
group by userid;


# (3)點選預測比例天數(predictgame.php?action=scale)
create table actionlog._predictscale_1 engine = myisam
select a.userid, a.d, count(a.uri) as c
from (
    SELECT userid, uri, date(time) as d 
    FROM actionlog._predictscale) as a
group by a.userid, a.d;

create table actionlog._predictscale_2 engine = myisam
SELECT userid, count(d) as click_predictscale
FROM actionlog._predictscale_1
where d between subdate(now(),94) and now() 
group by userid;


# 手機/電腦使用比率
CREATE TABLE actionlog._action_livescore_1 engine = myisam
SELECT a.userid, a.devices, count(a.userid) as c
FROM (
    SELECT userid, (case when (platform_type<2) then 'desktop_pv' else 'mobile_pv' end) as devices
    FROM actionlog._livescore) as a
GROUP BY a.userid, a.devices;

CREATE TABLE actionlog._action_livescore_2 engine = myisam
SELECT a.userid, sum(a.desktop_pv) as desktop_pv, sum(a.mobile_pv) as mobile_pv
FROM (
    SELECT userid, (case when (devices='desktop_pv') then c else 0 end) as desktop_pv, 
                   (case when (devices='mobile_pv') then c else 0 end) as mobile_pv
    FROM actionlog._action_livescore_1) as a
GROUP BY a.userid;

CREATE TABLE actionlog._action_livescore_3 engine = myisam
SELECT userid, desktop_pv, mobile_pv, round(desktop_pv/(desktop_pv+mobile_pv),2) as desktop_p, 
                                      round(mobile_pv/(desktop_pv+mobile_pv),2) as mobile_p
FROM actionlog._action_livescore_2;

# 開始join名單
        ALTER TABLE actionlog._from_app_6 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._livescore_nextday_4 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._gamedata_2 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._predictscale_2 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._action_livescore_3 convert to character set utf8 collate utf8_general_ci;
        
create table plsport_playsport._list_1 engine = myisam
SELECT a.userid, b.nickname, a.click_and, a.click_ios, a.days_and, a.days_ios
FROM actionlog._from_app_6 a left join plsport_playsport.member b on a.userid = b.userid;

create table plsport_playsport._list_2 engine = myisam
select a.userid, a.nickname, (case when (a.p_and>0.975) then 'Andriod' else 'iOS' end) as os, 
       (a.click_and+a.click_ios) as click_title, (a.days_and+a.days_ios) as click_days
from (
    SELECT userid, nickname, click_and, click_ios, days_and, days_ios, round((click_and/(click_and+click_ios)),3) as p_and,
                                                                       round((click_ios/(click_and+click_ios)),3) as p_ios
    FROM plsport_playsport._list_1) as a;

create table plsport_playsport._list_3 engine = myisam
SELECT a.userid, a.nickname, a.os, a.click_title, a.click_days, b.click_nextday
FROM plsport_playsport._list_2 a left join actionlog._livescore_nextday_4 b on a.userid = b.userid;

create table plsport_playsport._list_4 engine = myisam
SELECT a.userid, a.nickname, a.os, a.click_title, a.click_days, a.click_nextday, b.click_gamedata
FROM plsport_playsport._list_3 a left join actionlog._gamedata_2 b on a.userid = b.userid;

create table plsport_playsport._list_5 engine = myisam
SELECT a.userid, a.nickname, a.os, a.click_title, a.click_days, a.click_nextday, a.click_gamedata, b.click_predictscale
FROM plsport_playsport._list_4 a left join actionlog._predictscale_2 b on a.userid = b.userid;

# 在這裡要先跑居住地

ALTER TABLE plsport_playsport._user_city ADD INDEX (`userid`);


create table plsport_playsport._list_6 engine = myisam
SELECT a.userid, a.nickname, a.os, a.click_title, a.click_days, a.click_nextday, a.click_gamedata, a.click_predictscale,
       b.city
FROM plsport_playsport._list_5 a left join plsport_playsport._user_city b on a.userid = b.userid;

create table plsport_playsport._list_7 engine = myisam
SELECT a.userid, a.nickname, a.os, a.click_title, a.click_days, a.click_nextday, a.click_gamedata, a.click_predictscale,
       b.desktop_pv, b.mobile_pv, b.desktop_p, b.mobile_p ,a.city
FROM plsport_playsport._list_6 a left join actionlog._action_livescore_3 b on a.userid = b.userid;

# 每個人最後一次登入是何日
CREATE TABLE plsport_playsport._last_time_login engine = myisam
SELECT userid, date(max(signin_time)) as last_time_login
FROM plsport_playsport.member_signin_log_archive
GROUP BY userid;

ALTER TABLE plsport_playsport._last_time_login ADD INDEX (`userid`);
ALTER TABLE plsport_playsport._last_time_login convert to character set utf8 collate utf8_general_ci;

create table plsport_playsport._list_8 engine = myisam
SELECT a.userid, a.nickname, a.os, a.click_title, a.click_days, a.click_nextday, a.click_gamedata, a.click_predictscale,
       a.desktop_pv, a.mobile_pv, a.desktop_p, a.mobile_p ,a.city, date(b.last_time_login) as last_time_login
FROM plsport_playsport._list_7 a left join plsport_playsport._last_time_login b on a.userid = b.userid;

SELECT 'userid', 'nickname', '手機系統', 'APP版標點選天數', 'APP版標點選次數', '點選即時比分NBA隔日天數', '點選賽事數據天數', '點選預測比例天數',
       '即時比分電腦pv', '即時比分手機pv', '電腦使用比例', '手機使用比例', '居住地', '最後登入' union (
SELECT userid, nickname, os, click_days, click_title, click_nextday, click_gamedata, click_predictscale,
       desktop_pv, mobile_pv, desktop_p, mobile_p, city, last_time_login
into outfile 'C:/Users/1-7_ASUS/Desktop/_list_8.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._list_8);



# =================================================================================================
# 任務: [201412-B-2]優化手機預測賽事頁面-現場測試名單撈取 [新建] (靜怡) 2015-03-19
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4445&projectId=11
# 提供測試名單
# 
# 需求
# - 撈取時間:近三個月
# - 需求欄位:暱稱、ID、預測點擊天數、電腦與手機使用比、最後登入時間，居住地
# =================================================================================================

# 要先準備好 (1)最新的prediction (2)跑user_city.py


create table actionlog._visit_member_201501 engine = myisam
SELECT userid, uri, time, (case when (platform_type<2) then 'pc' else 'mobile' end) as p
FROM actionlog.action_201501 where userid <> '' and uri like '%visit_member.php%';
create table actionlog._visit_member_201502 engine = myisam
SELECT userid, uri, time, (case when (platform_type<2) then 'pc' else 'mobile' end) as p
FROM actionlog.action_201502 where userid <> '' and uri like '%visit_member.php%';
create table actionlog._visit_member_201503 engine = myisam
SELECT userid, uri, time, (case when (platform_type<2) then 'pc' else 'mobile' end) as p
FROM actionlog.action_201503 where userid <> '' and uri like '%visit_member.php%';
create table actionlog._visit_member_201504 engine = myisam
SELECT userid, uri, time, (case when (platform_type<2) then 'pc' else 'mobile' end) as p
FROM actionlog.action_201504 where userid <> '' and uri like '%visit_member.php%';
create table actionlog._visit_member_201505 engine = myisam
SELECT userid, uri, time, (case when (platform_type<2) then 'pc' else 'mobile' end) as p
FROM actionlog.action_201505 where userid <> '' and uri like '%visit_member.php%';
create table actionlog._visit_member_201506 engine = myisam
SELECT userid, uri, time, (case when (platform_type<2) then 'pc' else 'mobile' end) as p
FROM actionlog.action_201506 where userid <> '' and uri like '%visit_member.php%';

create table actionlog._visit_member engine = myisam select * from actionlog._visit_member_201501;
insert ignore into actionlog._visit_member select * from actionlog._visit_member_201502;
insert ignore into actionlog._visit_member select * from actionlog._visit_member_201503;
insert ignore into actionlog._visit_member select * from actionlog._visit_member_201504;
insert ignore into actionlog._visit_member select * from actionlog._visit_member_201505;
insert ignore into actionlog._visit_member select * from actionlog._visit_member_201506;

create table actionlog._visit_member_1 engine = myisam
SELECT * FROM actionlog._visit_member
where time between subdate(now(),91) and now();

create table actionlog._visit_member_2 engine = myisam
SELECT userid, p, count(p) as pv 
FROM actionlog._visit_member_1
group by userid, p;

create table actionlog._visit_member_3 engine = myisam
select a.userid, sum(a.pc) as pc, sum(a.mobile) as mobile
from (
    SELECT userid, (case when (p='pc') then pv else 0 end) as pc, (case when (p='mobile') then pv else 0 end) as mobile
    FROM actionlog._visit_member_2) as a
group by a.userid;

create table actionlog._visit_member_4 engine = myisam
SELECT userid, pc, mobile, round((pc/(pc+mobile)),3) as p_pc, round((mobile/(pc+mobile)),3) as p_mobile 
FROM actionlog._visit_member_3;

create table plsport_playsport._prediction_201501 engine = myisam SELECT userid, createday, count(userid) as c FROM prediction.p_201501 group by userid, createday;
create table plsport_playsport._prediction_201502 engine = myisam SELECT userid, createday, count(userid) as c FROM prediction.p_201502 group by userid, createday;
create table plsport_playsport._prediction_201503 engine = myisam SELECT userid, createday, count(userid) as c FROM prediction.p_201503 group by userid, createday;
create table plsport_playsport._prediction_201504 engine = myisam SELECT userid, createday, count(userid) as c FROM prediction.p_201504 group by userid, createday;
create table plsport_playsport._prediction_201505 engine = myisam SELECT userid, createday, count(userid) as c FROM prediction.p_201505 group by userid, createday;
create table plsport_playsport._prediction_201506 engine = myisam SELECT userid, createday, count(userid) as c FROM prediction.p_201506 group by userid, createday;

create table plsport_playsport._prediction engine = myisam select * from plsport_playsport._prediction_201501;
insert ignore into plsport_playsport._prediction select * from plsport_playsport._prediction_201502;
insert ignore into plsport_playsport._prediction select * from plsport_playsport._prediction_201503;
insert ignore into plsport_playsport._prediction select * from plsport_playsport._prediction_201504;
insert ignore into plsport_playsport._prediction select * from plsport_playsport._prediction_201505;
insert ignore into plsport_playsport._prediction select * from plsport_playsport._prediction_201506;

create table plsport_playsport._prediction_1 engine = myisam
SELECT userid, count(createday) as predict_day_count
FROM plsport_playsport._prediction
where createday between subdate(now(),91) and now() 
group by userid;

# 每個人最後一次登入是何日
CREATE TABLE plsport_playsport._last_time_login engine = myisam
SELECT userid, date(max(signin_time)) as last_time_login
FROM plsport_playsport.member_signin_log_archive
GROUP BY userid;

        ALTER TABLE plsport_playsport._prediction_1 ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._prediction_1 convert to character set utf8 collate utf8_general_ci;

create table plsport_playsport._predict_list_1 engine = myisam
SELECT a.userid, b.nickname, a.predict_day_count 
FROM plsport_playsport._prediction_1 a left join plsport_playsport.member b on a.userid = b.userid;

        ALTER TABLE actionlog._visit_member_4 ADD INDEX (`userid`);
        ALTER TABLE actionlog._visit_member_4 convert to character set utf8 collate utf8_general_ci;

create table plsport_playsport._predict_list_2 engine = myisam
SELECT a.userid, a.nickname, a.predict_day_count, b.pc, b.mobile, b.p_pc, b.p_mobile
FROM plsport_playsport._predict_list_1 a left join actionlog._visit_member_4 b on a.userid = b.userid;

        ALTER TABLE plsport_playsport._predict_list_2 ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._last_time_login ADD INDEX (`userid`);


create table plsport_playsport._predict_list_3 engine = myisam
SELECT a.userid, a.nickname, a.predict_day_count, a.pc, a.mobile, a.p_pc, a.p_mobile, b.last_time_login
FROM plsport_playsport._predict_list_2 a left join plsport_playsport._last_time_login b on a.userid = b.userid;

# 在這裡要先跑居住地(step16_user_city.py)

        ALTER TABLE plsport_playsport._user_city ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._user_city convert to character set utf8 collate utf8_general_ci;

create table plsport_playsport._predict_list_4 engine = myisam
SELECT a.userid, a.nickname, a.predict_day_count, a.pc, a.mobile, a.p_pc, a.p_mobile, a.last_time_login, b.city
FROM plsport_playsport._predict_list_3 a left join plsport_playsport._user_city b on a.userid = b.userid;

SELECT 'userid', '暱稱', '預測點擊天數', 'pc_pv', 'mobile_pv', 'pc比例', 'mobile比例' ,'最後登入', '居住地' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_predict_list_4.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._predict_list_4);



# =================================================================================================
# 任務: 分析文新規則成本試算 [新建] (柔雅) 2015-03-20
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4428&projectId=11
# 
# 麻煩協助撈取，分析文寫手的表現。
# 條件:
# 1.曾經當選過一次，優質分析王
# 需求:
# 請撈取有達到條件的版友，2014年中，每一個月的"分析文"流量，
# 有分析文標籤才列入計算、刪除的文章不列入計算。
# 再麻煩你回覆哪時可以告知結果。
# =================================================================================================

create table actionlog._forumdetail_201401 engine = myisam
SELECT userid, uri, time, cookie_stamp FROM actionlog.action_201401 where uri like '%/forumdetail.php%';
create table actionlog._forumdetail_201402 engine = myisam
SELECT userid, uri, time, cookie_stamp FROM actionlog.action_201402 where uri like '%/forumdetail.php%';
create table actionlog._forumdetail_201403 engine = myisam
SELECT userid, uri, time, cookie_stamp FROM actionlog.action_201403 where uri like '%/forumdetail.php%';
create table actionlog._forumdetail_201404 engine = myisam
SELECT userid, uri, time, cookie_stamp FROM actionlog.action_201404 where uri like '%/forumdetail.php%';
create table actionlog._forumdetail_201405 engine = myisam
SELECT userid, uri, time, cookie_stamp FROM actionlog.action_201405 where uri like '%/forumdetail.php%';
create table actionlog._forumdetail_201406 engine = myisam
SELECT userid, uri, time, cookie_stamp FROM actionlog.action_201406 where uri like '%/forumdetail.php%';
create table actionlog._forumdetail_201407 engine = myisam
SELECT userid, uri, time, cookie_stamp FROM actionlog.action_201407 where uri like '%/forumdetail.php%';
create table actionlog._forumdetail_201408 engine = myisam
SELECT userid, uri, time, cookie_stamp FROM actionlog.action_201408 where uri like '%/forumdetail.php%';
create table actionlog._forumdetail_201409 engine = myisam
SELECT userid, uri, time, cookie_stamp FROM actionlog.action_201409 where uri like '%/forumdetail.php%';
create table actionlog._forumdetail_201410 engine = myisam
SELECT userid, uri, time, cookie_stamp FROM actionlog.action_201410 where uri like '%/forumdetail.php%';
create table actionlog._forumdetail_201411 engine = myisam
SELECT userid, uri, time, cookie_stamp FROM actionlog.action_201411 where uri like '%/forumdetail.php%';
create table actionlog._forumdetail_201412 engine = myisam
SELECT userid, uri, time, cookie_stamp FROM actionlog.action_201412 where uri like '%/forumdetail.php%';

create table actionlog._forumdetail_1_201401 engine = myisam
select a.userid, a.uri, a.time, a.cookie_stamp, (case when (locate('&',a.s)=0) then a.s else substr(a.s,1,locate('&',a.s)-1) end) as s
from (SELECT userid, uri, time, cookie_stamp, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._forumdetail_201401) as a;
create table actionlog._forumdetail_1_201402 engine = myisam
select a.userid, a.uri, a.time, a.cookie_stamp, (case when (locate('&',a.s)=0) then a.s else substr(a.s,1,locate('&',a.s)-1) end) as s
from (SELECT userid, uri, time, cookie_stamp, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._forumdetail_201402) as a;
create table actionlog._forumdetail_1_201403 engine = myisam
select a.userid, a.uri, a.time, a.cookie_stamp, (case when (locate('&',a.s)=0) then a.s else substr(a.s,1,locate('&',a.s)-1) end) as s
from (SELECT userid, uri, time, cookie_stamp, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._forumdetail_201403) as a;
create table actionlog._forumdetail_1_201404 engine = myisam
select a.userid, a.uri, a.time, a.cookie_stamp, (case when (locate('&',a.s)=0) then a.s else substr(a.s,1,locate('&',a.s)-1) end) as s
from (SELECT userid, uri, time, cookie_stamp, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._forumdetail_201404) as a;
create table actionlog._forumdetail_1_201405 engine = myisam
select a.userid, a.uri, a.time, a.cookie_stamp, (case when (locate('&',a.s)=0) then a.s else substr(a.s,1,locate('&',a.s)-1) end) as s
from (SELECT userid, uri, time, cookie_stamp, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._forumdetail_201405) as a;
create table actionlog._forumdetail_1_201406 engine = myisam
select a.userid, a.uri, a.time, a.cookie_stamp, (case when (locate('&',a.s)=0) then a.s else substr(a.s,1,locate('&',a.s)-1) end) as s
from (SELECT userid, uri, time, cookie_stamp, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._forumdetail_201406) as a;
create table actionlog._forumdetail_1_201407 engine = myisam
select a.userid, a.uri, a.time, a.cookie_stamp, (case when (locate('&',a.s)=0) then a.s else substr(a.s,1,locate('&',a.s)-1) end) as s
from (SELECT userid, uri, time, cookie_stamp, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._forumdetail_201407) as a;
create table actionlog._forumdetail_1_201408 engine = myisam
select a.userid, a.uri, a.time, a.cookie_stamp, (case when (locate('&',a.s)=0) then a.s else substr(a.s,1,locate('&',a.s)-1) end) as s
from (SELECT userid, uri, time, cookie_stamp, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._forumdetail_201408) as a;
create table actionlog._forumdetail_1_201409 engine = myisam
select a.userid, a.uri, a.time, a.cookie_stamp, (case when (locate('&',a.s)=0) then a.s else substr(a.s,1,locate('&',a.s)-1) end) as s
from (SELECT userid, uri, time, cookie_stamp, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._forumdetail_201409) as a;
create table actionlog._forumdetail_1_201410 engine = myisam
select a.userid, a.uri, a.time, a.cookie_stamp, (case when (locate('&',a.s)=0) then a.s else substr(a.s,1,locate('&',a.s)-1) end) as s
from (SELECT userid, uri, time, cookie_stamp, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._forumdetail_201410) as a;
create table actionlog._forumdetail_1_201411 engine = myisam
select a.userid, a.uri, a.time, a.cookie_stamp, (case when (locate('&',a.s)=0) then a.s else substr(a.s,1,locate('&',a.s)-1) end) as s
from (SELECT userid, uri, time, cookie_stamp, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._forumdetail_201411) as a;
create table actionlog._forumdetail_1_201412 engine = myisam
select a.userid, a.uri, a.time, a.cookie_stamp, (case when (locate('&',a.s)=0) then a.s else substr(a.s,1,locate('&',a.s)-1) end) as s
from (SELECT userid, uri, time, cookie_stamp, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._forumdetail_201412) as a;

create table plsport_playsport._analysis_post engine = myisam
SELECT subjectid, allianceid, postuser, posttime
FROM plsport_playsport.forum
where gametype=1 and year(posttime)=2014;

        ALTER TABLE actionlog._forumdetail_1_201401 CHANGE `s` `s` VARCHAR(45) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE actionlog._forumdetail_1_201402 CHANGE `s` `s` VARCHAR(45) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE actionlog._forumdetail_1_201403 CHANGE `s` `s` VARCHAR(45) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE actionlog._forumdetail_1_201404 CHANGE `s` `s` VARCHAR(45) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE actionlog._forumdetail_1_201405 CHANGE `s` `s` VARCHAR(45) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE actionlog._forumdetail_1_201406 CHANGE `s` `s` VARCHAR(45) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE actionlog._forumdetail_1_201407 CHANGE `s` `s` VARCHAR(45) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE actionlog._forumdetail_1_201408 CHANGE `s` `s` VARCHAR(45) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE actionlog._forumdetail_1_201409 CHANGE `s` `s` VARCHAR(45) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE actionlog._forumdetail_1_201410 CHANGE `s` `s` VARCHAR(45) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE actionlog._forumdetail_1_201411 CHANGE `s` `s` VARCHAR(45) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE actionlog._forumdetail_1_201412 CHANGE `s` `s` VARCHAR(45) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE plsport_playsport._analysis_post ADD INDEX (`subjectid`, `postuser`);
        ALTER TABLE plsport_playsport._analysis_post convert to character set utf8 collate utf8_general_ci;

create table actionlog._forumdetail_2_201401 engine = myisam SELECT userid, uri, time, cookie_stamp, s FROM actionlog._forumdetail_1_201401 a inner join plsport_playsport._analysis_post b on a.s = b.subjectid;
create table actionlog._forumdetail_2_201402 engine = myisam SELECT userid, uri, time, cookie_stamp, s FROM actionlog._forumdetail_1_201402 a inner join plsport_playsport._analysis_post b on a.s = b.subjectid;
create table actionlog._forumdetail_2_201403 engine = myisam SELECT userid, uri, time, cookie_stamp, s FROM actionlog._forumdetail_1_201403 a inner join plsport_playsport._analysis_post b on a.s = b.subjectid;
create table actionlog._forumdetail_2_201404 engine = myisam SELECT userid, uri, time, cookie_stamp, s FROM actionlog._forumdetail_1_201404 a inner join plsport_playsport._analysis_post b on a.s = b.subjectid;
create table actionlog._forumdetail_2_201405 engine = myisam SELECT userid, uri, time, cookie_stamp, s FROM actionlog._forumdetail_1_201405 a inner join plsport_playsport._analysis_post b on a.s = b.subjectid;
create table actionlog._forumdetail_2_201406 engine = myisam SELECT userid, uri, time, cookie_stamp, s FROM actionlog._forumdetail_1_201406 a inner join plsport_playsport._analysis_post b on a.s = b.subjectid;
create table actionlog._forumdetail_2_201407 engine = myisam SELECT userid, uri, time, cookie_stamp, s FROM actionlog._forumdetail_1_201407 a inner join plsport_playsport._analysis_post b on a.s = b.subjectid;
create table actionlog._forumdetail_2_201408 engine = myisam SELECT userid, uri, time, cookie_stamp, s FROM actionlog._forumdetail_1_201408 a inner join plsport_playsport._analysis_post b on a.s = b.subjectid;
create table actionlog._forumdetail_2_201409 engine = myisam SELECT userid, uri, time, cookie_stamp, s FROM actionlog._forumdetail_1_201409 a inner join plsport_playsport._analysis_post b on a.s = b.subjectid;
create table actionlog._forumdetail_2_201410 engine = myisam SELECT userid, uri, time, cookie_stamp, s FROM actionlog._forumdetail_1_201410 a inner join plsport_playsport._analysis_post b on a.s = b.subjectid;
create table actionlog._forumdetail_2_201411 engine = myisam SELECT userid, uri, time, cookie_stamp, s FROM actionlog._forumdetail_1_201411 a inner join plsport_playsport._analysis_post b on a.s = b.subjectid;
create table actionlog._forumdetail_2_201412 engine = myisam SELECT userid, uri, time, cookie_stamp, s FROM actionlog._forumdetail_1_201412 a inner join plsport_playsport._analysis_post b on a.s = b.subjectid;

create table actionlog._forumdetail_3_201401 engine = myisam SELECT cookie_stamp, s, count(uri) as c FROM actionlog._forumdetail_2_201401 group by cookie_stamp, s;
create table actionlog._forumdetail_3_201402 engine = myisam SELECT cookie_stamp, s, count(uri) as c FROM actionlog._forumdetail_2_201402 group by cookie_stamp, s;
create table actionlog._forumdetail_3_201403 engine = myisam SELECT cookie_stamp, s, count(uri) as c FROM actionlog._forumdetail_2_201403 group by cookie_stamp, s;
create table actionlog._forumdetail_3_201404 engine = myisam SELECT cookie_stamp, s, count(uri) as c FROM actionlog._forumdetail_2_201404 group by cookie_stamp, s;
create table actionlog._forumdetail_3_201405 engine = myisam SELECT cookie_stamp, s, count(uri) as c FROM actionlog._forumdetail_2_201405 group by cookie_stamp, s;
create table actionlog._forumdetail_3_201406 engine = myisam SELECT cookie_stamp, s, count(uri) as c FROM actionlog._forumdetail_2_201406 group by cookie_stamp, s;
create table actionlog._forumdetail_3_201407 engine = myisam SELECT cookie_stamp, s, count(uri) as c FROM actionlog._forumdetail_2_201407 group by cookie_stamp, s;
create table actionlog._forumdetail_3_201408 engine = myisam SELECT cookie_stamp, s, count(uri) as c FROM actionlog._forumdetail_2_201408 group by cookie_stamp, s;
create table actionlog._forumdetail_3_201409 engine = myisam SELECT cookie_stamp, s, count(uri) as c FROM actionlog._forumdetail_2_201409 group by cookie_stamp, s;
create table actionlog._forumdetail_3_201410 engine = myisam SELECT cookie_stamp, s, count(uri) as c FROM actionlog._forumdetail_2_201410 group by cookie_stamp, s;
create table actionlog._forumdetail_3_201411 engine = myisam SELECT cookie_stamp, s, count(uri) as c FROM actionlog._forumdetail_2_201411 group by cookie_stamp, s;
create table actionlog._forumdetail_3_201412 engine = myisam SELECT cookie_stamp, s, count(uri) as c FROM actionlog._forumdetail_2_201412 group by cookie_stamp, s;

create table actionlog._forumdetail_4_201401 engine = myisam SELECT s as subjectid, count(cookie_stamp) as views FROM actionlog._forumdetail_3_201401 group by s;
create table actionlog._forumdetail_4_201402 engine = myisam SELECT s as subjectid, count(cookie_stamp) as views FROM actionlog._forumdetail_3_201402 group by s;
create table actionlog._forumdetail_4_201403 engine = myisam SELECT s as subjectid, count(cookie_stamp) as views FROM actionlog._forumdetail_3_201403 group by s;
create table actionlog._forumdetail_4_201404 engine = myisam SELECT s as subjectid, count(cookie_stamp) as views FROM actionlog._forumdetail_3_201404 group by s;
create table actionlog._forumdetail_4_201405 engine = myisam SELECT s as subjectid, count(cookie_stamp) as views FROM actionlog._forumdetail_3_201405 group by s;
create table actionlog._forumdetail_4_201406 engine = myisam SELECT s as subjectid, count(cookie_stamp) as views FROM actionlog._forumdetail_3_201406 group by s;
create table actionlog._forumdetail_4_201407 engine = myisam SELECT s as subjectid, count(cookie_stamp) as views FROM actionlog._forumdetail_3_201407 group by s;
create table actionlog._forumdetail_4_201408 engine = myisam SELECT s as subjectid, count(cookie_stamp) as views FROM actionlog._forumdetail_3_201408 group by s;
create table actionlog._forumdetail_4_201409 engine = myisam SELECT s as subjectid, count(cookie_stamp) as views FROM actionlog._forumdetail_3_201409 group by s;
create table actionlog._forumdetail_4_201410 engine = myisam SELECT s as subjectid, count(cookie_stamp) as views FROM actionlog._forumdetail_3_201410 group by s;
create table actionlog._forumdetail_4_201411 engine = myisam SELECT s as subjectid, count(cookie_stamp) as views FROM actionlog._forumdetail_3_201411 group by s;
create table actionlog._forumdetail_4_201412 engine = myisam SELECT s as subjectid, count(cookie_stamp) as views FROM actionlog._forumdetail_3_201412 group by s;

create table actionlog._forumdetail_5_201401 engine = myisam SELECT (case when (subjectid is not null) then '201401' else '' end) as m, subjectid, views FROM actionlog._forumdetail_4_201401;
create table actionlog._forumdetail_5_201402 engine = myisam SELECT (case when (subjectid is not null) then '201402' else '' end) as m, subjectid, views FROM actionlog._forumdetail_4_201402;
create table actionlog._forumdetail_5_201403 engine = myisam SELECT (case when (subjectid is not null) then '201403' else '' end) as m, subjectid, views FROM actionlog._forumdetail_4_201403;
create table actionlog._forumdetail_5_201404 engine = myisam SELECT (case when (subjectid is not null) then '201404' else '' end) as m, subjectid, views FROM actionlog._forumdetail_4_201404;
create table actionlog._forumdetail_5_201405 engine = myisam SELECT (case when (subjectid is not null) then '201405' else '' end) as m, subjectid, views FROM actionlog._forumdetail_4_201405;
create table actionlog._forumdetail_5_201406 engine = myisam SELECT (case when (subjectid is not null) then '201406' else '' end) as m, subjectid, views FROM actionlog._forumdetail_4_201406;
create table actionlog._forumdetail_5_201407 engine = myisam SELECT (case when (subjectid is not null) then '201407' else '' end) as m, subjectid, views FROM actionlog._forumdetail_4_201407;
create table actionlog._forumdetail_5_201408 engine = myisam SELECT (case when (subjectid is not null) then '201408' else '' end) as m, subjectid, views FROM actionlog._forumdetail_4_201408;
create table actionlog._forumdetail_5_201409 engine = myisam SELECT (case when (subjectid is not null) then '201409' else '' end) as m, subjectid, views FROM actionlog._forumdetail_4_201409;
create table actionlog._forumdetail_5_201410 engine = myisam SELECT (case when (subjectid is not null) then '201410' else '' end) as m, subjectid, views FROM actionlog._forumdetail_4_201410;
create table actionlog._forumdetail_5_201411 engine = myisam SELECT (case when (subjectid is not null) then '201411' else '' end) as m, subjectid, views FROM actionlog._forumdetail_4_201411;
create table actionlog._forumdetail_5_201412 engine = myisam SELECT (case when (subjectid is not null) then '201411' else '' end) as m, subjectid, views FROM actionlog._forumdetail_4_201412;

create table actionlog._forumdetail_6_201401 engine = myisam SELECT a.m, b.postuser, a.subjectid, a.views FROM actionlog._forumdetail_5_201401 a left join plsport_playsport._analysis_post_1 b on a.subjectid = b.subjectid;
create table actionlog._forumdetail_6_201402 engine = myisam SELECT a.m, b.postuser, a.subjectid, a.views FROM actionlog._forumdetail_5_201402 a left join plsport_playsport._analysis_post_1 b on a.subjectid = b.subjectid;
create table actionlog._forumdetail_6_201403 engine = myisam SELECT a.m, b.postuser, a.subjectid, a.views FROM actionlog._forumdetail_5_201403 a left join plsport_playsport._analysis_post_1 b on a.subjectid = b.subjectid;
create table actionlog._forumdetail_6_201404 engine = myisam SELECT a.m, b.postuser, a.subjectid, a.views FROM actionlog._forumdetail_5_201404 a left join plsport_playsport._analysis_post_1 b on a.subjectid = b.subjectid;
create table actionlog._forumdetail_6_201405 engine = myisam SELECT a.m, b.postuser, a.subjectid, a.views FROM actionlog._forumdetail_5_201405 a left join plsport_playsport._analysis_post_1 b on a.subjectid = b.subjectid;
create table actionlog._forumdetail_6_201406 engine = myisam SELECT a.m, b.postuser, a.subjectid, a.views FROM actionlog._forumdetail_5_201406 a left join plsport_playsport._analysis_post_1 b on a.subjectid = b.subjectid;
create table actionlog._forumdetail_6_201407 engine = myisam SELECT a.m, b.postuser, a.subjectid, a.views FROM actionlog._forumdetail_5_201407 a left join plsport_playsport._analysis_post_1 b on a.subjectid = b.subjectid;
create table actionlog._forumdetail_6_201408 engine = myisam SELECT a.m, b.postuser, a.subjectid, a.views FROM actionlog._forumdetail_5_201408 a left join plsport_playsport._analysis_post_1 b on a.subjectid = b.subjectid;
create table actionlog._forumdetail_6_201409 engine = myisam SELECT a.m, b.postuser, a.subjectid, a.views FROM actionlog._forumdetail_5_201409 a left join plsport_playsport._analysis_post_1 b on a.subjectid = b.subjectid;
create table actionlog._forumdetail_6_201410 engine = myisam SELECT a.m, b.postuser, a.subjectid, a.views FROM actionlog._forumdetail_5_201410 a left join plsport_playsport._analysis_post_1 b on a.subjectid = b.subjectid;
create table actionlog._forumdetail_6_201411 engine = myisam SELECT a.m, b.postuser, a.subjectid, a.views FROM actionlog._forumdetail_5_201411 a left join plsport_playsport._analysis_post_1 b on a.subjectid = b.subjectid;
create table actionlog._forumdetail_6_201412 engine = myisam SELECT a.m, b.postuser, a.subjectid, a.views FROM actionlog._forumdetail_5_201412 a left join plsport_playsport._analysis_post_1 b on a.subjectid = b.subjectid;

create table actionlog._forumdetail_6 engine = myisam SELECT * FROM actionlog._forumdetail_6_201401;
insert ignore into actionlog._forumdetail_6 SELECT * FROM actionlog._forumdetail_6_201402; 
insert ignore into actionlog._forumdetail_6 SELECT * FROM actionlog._forumdetail_6_201403; 
insert ignore into actionlog._forumdetail_6 SELECT * FROM actionlog._forumdetail_6_201404; 
insert ignore into actionlog._forumdetail_6 SELECT * FROM actionlog._forumdetail_6_201405; 
insert ignore into actionlog._forumdetail_6 SELECT * FROM actionlog._forumdetail_6_201406; 
insert ignore into actionlog._forumdetail_6 SELECT * FROM actionlog._forumdetail_6_201407; 
insert ignore into actionlog._forumdetail_6 SELECT * FROM actionlog._forumdetail_6_201408; 
insert ignore into actionlog._forumdetail_6 SELECT * FROM actionlog._forumdetail_6_201409; 
insert ignore into actionlog._forumdetail_6 SELECT * FROM actionlog._forumdetail_6_201410; 
insert ignore into actionlog._forumdetail_6 SELECT * FROM actionlog._forumdetail_6_201411; 
insert ignore into actionlog._forumdetail_6 SELECT * FROM actionlog._forumdetail_6_201412; 

create table actionlog._forumdetail_7 engine = myisam
SELECT m, postuser, (case when (views>499) then 1 else 0 end) as lv2,
                    (case when (views>2999) then 1 else 0 end) as lv3,
                    (case when (views>5999) then 1 else 0 end) as lv4
FROM actionlog._forumdetail_6;


create table actionlog._forumdetail_8 engine = myisam
SELECT m, postuser, sum(lv2) as lv2, sum(lv3) as lv3, sum(lv4) as lv4 
FROM actionlog._forumdetail_7
group by m, postuser;

create table actionlog._forumdetail_9 engine = myisam
SELECT * FROM actionlog._forumdetail_8
where (lv2 + lv3 + lv4) > 0
order by postuser, m;

create table actionlog._forumdetail_10_1 engine = myisam
SELECT postuser, substr(min(m),5,2) as lv2_m 
FROM actionlog._forumdetail_9
where lv2>0
group by postuser;

create table actionlog._forumdetail_10_2 engine = myisam
SELECT postuser, substr(min(m),5,2) as lv3_m 
FROM actionlog._forumdetail_9
where lv3>0
group by postuser;

create table actionlog._forumdetail_10_3 engine = myisam
SELECT postuser, substr(min(m),5,2) as lv4_m 
FROM actionlog._forumdetail_9
where lv4>0
group by postuser;

        ALTER TABLE actionlog._forumdetail_10_1 CHANGE `lv2_m` `lv2_m` INT(2) NULL DEFAULT NULL;
        ALTER TABLE actionlog._forumdetail_10_2 CHANGE `lv3_m` `lv3_m` INT(2) NULL DEFAULT NULL;
        ALTER TABLE actionlog._forumdetail_10_3 CHANGE `lv4_m` `lv4_m` INT(2) NULL DEFAULT NULL;

create table actionlog._forumdetail_11_1 engine = myisam SELECT postuser, (lv2_m+1) as lv2_m FROM actionlog._forumdetail_10_1;
create table actionlog._forumdetail_11_2 engine = myisam SELECT postuser, (lv3_m+1) as lv3_m FROM actionlog._forumdetail_10_2;
create table actionlog._forumdetail_11_3 engine = myisam SELECT postuser, (lv4_m+1) as lv4_m FROM actionlog._forumdetail_10_3;

create table actionlog._forumdetail_11_0 engine = myisam
SELECT poster, min(month) as lv1_m
FROM plsport_playsport.analysis_cost
where analysisking = 'yes'
group by poster;

create table actionlog._forumdetail_12_1 engine = myisam
SELECT a.poster, (a.lv1_m+1) as lv1_m, b.lv2_m
FROM actionlog._forumdetail_11_0 a left join actionlog._forumdetail_11_1 b on a.poster = b.postuser;

create table actionlog._forumdetail_12_2 engine = myisam
SELECT a.poster, a.lv1_m, a.lv2_m, b.lv3_m
FROM actionlog._forumdetail_12_1 a left join actionlog._forumdetail_11_2 b on a.poster = b.postuser;

create table actionlog._forumdetail_12_4 engine = myisam
SELECT a.poster, a.lv1_m, a.lv2_m, a.lv3_m, b.lv4_m
FROM actionlog._forumdetail_12_2 a left join actionlog._forumdetail_11_3 b on a.poster = b.postuser;


create table actionlog._forumdetail_13 engine = myisam
select a.poster, (a.lv1_m+a.lv2_m+a.lv3_m+a.lv4_m) as lv
from (
    SELECT poster, (case when (lv1_m>0) then 1 else 0 end) as lv1_m,
                   (case when (lv2_m>0) then 1 else 0 end) as lv2_m,
                   (case when (lv3_m>0) then 1 else 0 end) as lv3_m,
                   (case when (lv4_m>0) then 1 else 0 end) as lv4_m
    FROM actionlog._forumdetail_12_4) as a;

create table actionlog._forumdetail_14 engine = myisam
SELECT a.month, a.poster, a.viewed, a.percentile, a.analysisking, b.lv
FROM plsport_playsport.analysis_cost a left join actionlog._forumdetail_13 b on a.poster = b.poster;

create table actionlog._forumdetail_15 engine = myisam
SELECT a.month, a.poster, b.nickname, a.viewed, a.percentile, a.analysisking, a.lv 
FROM actionlog._forumdetail_14 a left join plsport_playsport.member b on a.poster = b.userid;

ALTER TABLE actionlog._forumdetail_15 CHANGE `viewed` `viewed` INT(10) NULL DEFAULT NULL;


create table actionlog._forumdetail_16 engine = myisam
SELECT a.month, a.poster, a.nickname, a.viewed, a.percentile, a.analysisking, b.v as rule1, a.lv as rule2
FROM actionlog._forumdetail_15 a left join (select e.poster, (e.v2+e.v3+e.v4)+1 as v
from (
    SELECT poster, (case when (max(viewed)>4999) then 1 else 0 end) as v2,
                   (case when (max(viewed)>19999) then 1 else 0 end) as v3,
                   (case when (max(viewed)>39999) then 1 else 0 end) as v4
    FROM actionlog._forumdetail_15
    group by poster) as e) as b on a.poster = b.poster;

create table actionlog._forumdetail_17 engine = myisam
SELECT month, poster, nickname, viewed, percentile, analysisking, rule1, rule2, (case when ( rule1<rule2) then rule1 else rule2 end) as lv
FROM actionlog._forumdetail_16;

SELECT 'month', 'poster', 'nickname', 'viewed', 'percentile', 'analysisking', 'rule1', 'rule2', 'level' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_forumdetail_15.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._forumdetail_17);

create table actionlog._forumdetail_10_a engine = myisam
SELECT a.m, a.postuser, a.lv2, a.lv3, a.lv4, b.lv2_m
FROM actionlog._forumdetail_9 a left join actionlog._forumdetail_10_1 b on a.postuser = b.postuser;

create table actionlog._forumdetail_10_b engine = myisam
SELECT a.m, a.postuser, a.lv2, a.lv3, a.lv4, a.lv2_m, b.lv3_m
FROM actionlog._forumdetail_10_a a left join actionlog._forumdetail_10_2 b on a.postuser = b.postuser;

create table actionlog._forumdetail_10_c engine = myisam
SELECT a.m, a.postuser, a.lv2, a.lv3, a.lv4, a.lv2_m, a.lv3_m, b.lv4_m
FROM actionlog._forumdetail_10_b a left join actionlog._forumdetail_10_3 b on a.postuser = b.postuser;

create table actionlog._forumdetail_4 engine = myisam SELECT * FROM actionlog._forumdetail_4_201401;
insert ignore into actionlog._forumdetail_4 SELECT * FROM actionlog._forumdetail_4_201402; 
insert ignore into actionlog._forumdetail_4 SELECT * FROM actionlog._forumdetail_4_201403; 
insert ignore into actionlog._forumdetail_4 SELECT * FROM actionlog._forumdetail_4_201404; 
insert ignore into actionlog._forumdetail_4 SELECT * FROM actionlog._forumdetail_4_201405; 
insert ignore into actionlog._forumdetail_4 SELECT * FROM actionlog._forumdetail_4_201406; 
insert ignore into actionlog._forumdetail_4 SELECT * FROM actionlog._forumdetail_4_201407; 
insert ignore into actionlog._forumdetail_4 SELECT * FROM actionlog._forumdetail_4_201408; 
insert ignore into actionlog._forumdetail_4 SELECT * FROM actionlog._forumdetail_4_201409; 
insert ignore into actionlog._forumdetail_4 SELECT * FROM actionlog._forumdetail_4_201410; 
insert ignore into actionlog._forumdetail_4 SELECT * FROM actionlog._forumdetail_4_201411; 
insert ignore into actionlog._forumdetail_4 SELECT * FROM actionlog._forumdetail_4_201412; 

create table actionlog._forumdetail_5 engine = myisam
SELECT subjectid, sum(views) as views
FROM actionlog._forumdetail_4
group by subjectid;
 
        ALTER TABLE actionlog._forumdetail_5 ADD INDEX (`subjectid`);
        ALTER TABLE actionlog._forumdetail_5 convert to character set utf8 collate utf8_general_ci;

create table plsport_playsport._analysis_post_1 engine = myisam
SELECT a.subjectid, a.allianceid, a.postuser, a.posttime, b.views
FROM plsport_playsport._analysis_post a left join actionlog._forumdetail_5 b on a.subjectid = b.subjectid;

create table plsport_playsport._analysis_post_2 engine = myisam
select a.m, a.postuser, sum(a.views) as views
from (
    SELECT postuser, month(posttime) as m, views 
    FROM plsport_playsport._analysis_post_1) as a
group by a.m, a.postuser;

create table plsport_playsport._analysis_post_3_201401 engine = myisam SELECT * FROM plsport_playsport._analysis_post_2 where m = 1 order by views desc;
create table plsport_playsport._analysis_post_3_201402 engine = myisam SELECT * FROM plsport_playsport._analysis_post_2 where m = 2 order by views desc;
create table plsport_playsport._analysis_post_3_201403 engine = myisam SELECT * FROM plsport_playsport._analysis_post_2 where m = 3 order by views desc;
create table plsport_playsport._analysis_post_3_201404 engine = myisam SELECT * FROM plsport_playsport._analysis_post_2 where m = 4 order by views desc;
create table plsport_playsport._analysis_post_3_201405 engine = myisam SELECT * FROM plsport_playsport._analysis_post_2 where m = 5 order by views desc;
create table plsport_playsport._analysis_post_3_201406 engine = myisam SELECT * FROM plsport_playsport._analysis_post_2 where m = 6 order by views desc;
create table plsport_playsport._analysis_post_3_201407 engine = myisam SELECT * FROM plsport_playsport._analysis_post_2 where m = 7 order by views desc;
create table plsport_playsport._analysis_post_3_201408 engine = myisam SELECT * FROM plsport_playsport._analysis_post_2 where m = 8 order by views desc;
create table plsport_playsport._analysis_post_3_201409 engine = myisam SELECT * FROM plsport_playsport._analysis_post_2 where m = 9 order by views desc;
create table plsport_playsport._analysis_post_3_201410 engine = myisam SELECT * FROM plsport_playsport._analysis_post_2 where m = 10 order by views desc;
create table plsport_playsport._analysis_post_3_201411 engine = myisam SELECT * FROM plsport_playsport._analysis_post_2 where m = 11 order by views desc;
create table plsport_playsport._analysis_post_3_201412 engine = myisam SELECT * FROM plsport_playsport._analysis_post_2 where m = 12 order by views desc;

create table plsport_playsport._analysis_post_4_201401 engine = myisam select m, postuser, views, round((cnt-rank+1)/cnt,2) as views_p
from (SELECT m, postuser, views, @curRank := @curRank + 1 AS rank FROM plsport_playsport._analysis_post_3_201401, (SELECT @curRank := 0) r
order by views desc) as dt, (select count(distinct postuser) as cnt from plsport_playsport._analysis_post_3_201401) as ct;
create table plsport_playsport._analysis_post_4_201402 engine = myisam select m, postuser, views, round((cnt-rank+1)/cnt,2) as views_p
from (SELECT m, postuser, views, @curRank := @curRank + 1 AS rank FROM plsport_playsport._analysis_post_3_201402, (SELECT @curRank := 0) r
order by views desc) as dt, (select count(distinct postuser) as cnt from plsport_playsport._analysis_post_3_201402) as ct;
create table plsport_playsport._analysis_post_4_201403 engine = myisam select m, postuser, views, round((cnt-rank+1)/cnt,2) as views_p
from (SELECT m, postuser, views, @curRank := @curRank + 1 AS rank FROM plsport_playsport._analysis_post_3_201403, (SELECT @curRank := 0) r
order by views desc) as dt, (select count(distinct postuser) as cnt from plsport_playsport._analysis_post_3_201403) as ct;
create table plsport_playsport._analysis_post_4_201404 engine = myisam select m, postuser, views, round((cnt-rank+1)/cnt,2) as views_p
from (SELECT m, postuser, views, @curRank := @curRank + 1 AS rank FROM plsport_playsport._analysis_post_3_201404, (SELECT @curRank := 0) r
order by views desc) as dt, (select count(distinct postuser) as cnt from plsport_playsport._analysis_post_3_201404) as ct;
create table plsport_playsport._analysis_post_4_201405 engine = myisam select m, postuser, views, round((cnt-rank+1)/cnt,2) as views_p
from (SELECT m, postuser, views, @curRank := @curRank + 1 AS rank FROM plsport_playsport._analysis_post_3_201405, (SELECT @curRank := 0) r
order by views desc) as dt, (select count(distinct postuser) as cnt from plsport_playsport._analysis_post_3_201405) as ct;
create table plsport_playsport._analysis_post_4_201406 engine = myisam select m, postuser, views, round((cnt-rank+1)/cnt,2) as views_p
from (SELECT m, postuser, views, @curRank := @curRank + 1 AS rank FROM plsport_playsport._analysis_post_3_201406, (SELECT @curRank := 0) r
order by views desc) as dt, (select count(distinct postuser) as cnt from plsport_playsport._analysis_post_3_201406) as ct;
create table plsport_playsport._analysis_post_4_201407 engine = myisam select m, postuser, views, round((cnt-rank+1)/cnt,2) as views_p
from (SELECT m, postuser, views, @curRank := @curRank + 1 AS rank FROM plsport_playsport._analysis_post_3_201407, (SELECT @curRank := 0) r
order by views desc) as dt, (select count(distinct postuser) as cnt from plsport_playsport._analysis_post_3_201407) as ct;
create table plsport_playsport._analysis_post_4_201408 engine = myisam select m, postuser, views, round((cnt-rank+1)/cnt,2) as views_p
from (SELECT m, postuser, views, @curRank := @curRank + 1 AS rank FROM plsport_playsport._analysis_post_3_201408, (SELECT @curRank := 0) r
order by views desc) as dt, (select count(distinct postuser) as cnt from plsport_playsport._analysis_post_3_201408) as ct;
create table plsport_playsport._analysis_post_4_201409 engine = myisam select m, postuser, views, round((cnt-rank+1)/cnt,2) as views_p
from (SELECT m, postuser, views, @curRank := @curRank + 1 AS rank FROM plsport_playsport._analysis_post_3_201409, (SELECT @curRank := 0) r
order by views desc) as dt, (select count(distinct postuser) as cnt from plsport_playsport._analysis_post_3_201409) as ct;
create table plsport_playsport._analysis_post_4_201410 engine = myisam select m, postuser, views, round((cnt-rank+1)/cnt,2) as views_p
from (SELECT m, postuser, views, @curRank := @curRank + 1 AS rank FROM plsport_playsport._analysis_post_3_201410, (SELECT @curRank := 0) r
order by views desc) as dt, (select count(distinct postuser) as cnt from plsport_playsport._analysis_post_3_201410) as ct;
create table plsport_playsport._analysis_post_4_201411 engine = myisam select m, postuser, views, round((cnt-rank+1)/cnt,2) as views_p
from (SELECT m, postuser, views, @curRank := @curRank + 1 AS rank FROM plsport_playsport._analysis_post_3_201411, (SELECT @curRank := 0) r
order by views desc) as dt, (select count(distinct postuser) as cnt from plsport_playsport._analysis_post_3_201411) as ct;
create table plsport_playsport._analysis_post_4_201412 engine = myisam select m, postuser, views, round((cnt-rank+1)/cnt,2) as views_p
from (SELECT m, postuser, views, @curRank := @curRank + 1 AS rank FROM plsport_playsport._analysis_post_3_201412, (SELECT @curRank := 0) r
order by views desc) as dt, (select count(distinct postuser) as cnt from plsport_playsport._analysis_post_3_201412) as ct;

create table plsport_playsport._analysis_post_4 engine = myisam SELECT * FROM plsport_playsport._analysis_post_4_201401;
insert ignore into plsport_playsport._analysis_post_4 SELECT * FROM plsport_playsport._analysis_post_4_201402;
insert ignore into plsport_playsport._analysis_post_4 SELECT * FROM plsport_playsport._analysis_post_4_201403;
insert ignore into plsport_playsport._analysis_post_4 SELECT * FROM plsport_playsport._analysis_post_4_201404;
insert ignore into plsport_playsport._analysis_post_4 SELECT * FROM plsport_playsport._analysis_post_4_201405;
insert ignore into plsport_playsport._analysis_post_4 SELECT * FROM plsport_playsport._analysis_post_4_201406;
insert ignore into plsport_playsport._analysis_post_4 SELECT * FROM plsport_playsport._analysis_post_4_201407;
insert ignore into plsport_playsport._analysis_post_4 SELECT * FROM plsport_playsport._analysis_post_4_201408;
insert ignore into plsport_playsport._analysis_post_4 SELECT * FROM plsport_playsport._analysis_post_4_201409;
insert ignore into plsport_playsport._analysis_post_4 SELECT * FROM plsport_playsport._analysis_post_4_201410;
insert ignore into plsport_playsport._analysis_post_4 SELECT * FROM plsport_playsport._analysis_post_4_201411;
insert ignore into plsport_playsport._analysis_post_4 SELECT * FROM plsport_playsport._analysis_post_4_201412;

        # 誰是每個月的優質分析王, 直接產出名單
        CREATE TABLE plsport_playsport._analysis_king_whoisbest engine = myisam
        SELECT b.userid, b.m, b.subjectid_count, (case when (b.userid is not null) then 'y' end) as best_analysis_king
        FROM (
            SELECT a.userid, a.m, count(a.subjectid) as subjectid_count
            FROM (
                SELECT userid, subjectid, substr(gamedate,1,6) as m 
                FROM plsport_playsport.analysis_king
                WHERE substr(gamedate,1,6) between '200901' AND '201412') as a #從以前到現在都算, 記得要調整區間
            GROUP BY a.userid, a.m
            ORDER BY a.m) as b 
        WHERE b.subjectid_count >11
        ORDER BY b.m, b.subjectid_count DESC;

        # 優質分析王不重覆的名單
        create table plsport_playsport._analysis_king_whoisbest_grouped engine = myisam
        SELECT userid, best_analysis_king 
        FROM plsport_playsport._analysis_king_whoisbest
        group by userid;


create table plsport_playsport._analysis_post_5 engine = myisam
select c.month, c.postuser, d.nickname, c.views, c.views_p, c.best_analysis_king
from (
    SELECT a.m as month, a.postuser, a.views, a.views_p, b.best_analysis_king
    FROM plsport_playsport._analysis_post_4 a left join plsport_playsport._analysis_king_whoisbest_grouped b on a.postuser = b.userid) as c
    left join plsport_playsport.member as d on c.postuser = d.userid;

SELECT '月份', '發文者', 'nickname', '文章被觀看次數', '當月級距', '是否曾當過優質分析王' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_new_analysis_post_cost_evaluation.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._analysis_post_5);


# update: 2015-04-09
# TO eddy:
# 查看過名單後，想麻煩您幫忙介定，寫手的等級，以利帶入稿費、試算成本。
# 
# 條件如下:
#         1.將寫手等級區分為: 新人、初級、中級、高級 四個等級。
#         2.領取稿費最低門檻為:至少當過一次優質分析王(則為新人等級)
#         3.條件表如下:
# 升級基本條件 	      新人寫手 	初級 	中級 	高級
# 單月累積人氣 	       不限 	5000 	20000 	40000
# 單篇分析文最高人氣 	不限 	500 	3000 	6000
# 單月最低發文數 	  	  	  	 
# 稿費金額/每千次瀏覽 	NT 10 	NT 25 	NT 50 	NT100

# 先匯入analysis_cost , 也就是_new_analysis_post_cost_evaluation.csv

create table plsport_playsport._analysis_list engine = myisam
SELECT poster 
FROM plsport_playsport.analysis_cost
group by poster;




# =================================================================================================
# 任務: [201404-B-5]手機網頁版header優化-MVP測試名單撈取 [新建] (靜怡) 20154-03-26
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4474&projectId=11
# 說明
#  
# 提供MVP測試名單
#  
# 需求
# - 撈取時間:近三個月
# - 需求欄位:暱稱、ID、討論區PV與比例、總PV、購買預測金額，電腦與手機使用比、最後登入時間
# =================================================================================================

# 總PV
create table actionlog._all_action_201412 engine = myisam
SELECT userid, uri, date(time) as d, platform_type  FROM actionlog.action_201412 where userid <> '';
create table actionlog._all_action_201501 engine = myisam
SELECT userid, uri, date(time) as d, platform_type  FROM actionlog.action_201501 where userid <> '';
create table actionlog._all_action_201502 engine = myisam
SELECT userid, uri, date(time) as d, platform_type  FROM actionlog.action_201502 where userid <> '';
create table actionlog._all_action_201503 engine = myisam
SELECT userid, uri, date(time) as d, platform_type  FROM actionlog.action_201503 where userid <> '';

create table actionlog._pv_all_action_201412 engine = myisam
SELECT userid, d, platform_type, count(userid) as c FROM actionlog._all_action_201412 group by userid, d, platform_type;
create table actionlog._pv_all_action_201501 engine = myisam
SELECT userid, d, platform_type, count(userid) as c FROM actionlog._all_action_201501 group by userid, d, platform_type;
create table actionlog._pv_all_action_201502 engine = myisam
SELECT userid, d, platform_type, count(userid) as c FROM actionlog._all_action_201502 group by userid, d, platform_type;
create table actionlog._pv_all_action_201503 engine = myisam
SELECT userid, d, platform_type, count(userid) as c FROM actionlog._all_action_201503 group by userid, d, platform_type;

create table actionlog._pv_all_action engine = myisam SELECT * FROM actionlog._pv_all_action_201412;
insert ignore into actionlog._pv_all_action SELECT * FROM actionlog._pv_all_action_201501;
insert ignore into actionlog._pv_all_action SELECT * FROM actionlog._pv_all_action_201502;
insert ignore into actionlog._pv_all_action SELECT * FROM actionlog._pv_all_action_201503;

create table actionlog._pv_all_action1 engine = myisam
select a.userid, a.p, sum(a.c) as pv
from (
    SELECT userid, d, (case when (platform_type<2) then 'pc' else 'mobile' end) as p, c
    FROM actionlog._pv_all_action
    where d between subdate(now(),91) and now()) as a
group by a.userid, a.p;

create table actionlog._pv_all_action2 engine = myisam
select b.userid, b.pc+b.mobile as total_pv, b.pc, b.mobile, round(b.pc/(b.pc+b.mobile),3) as p_pc, round(b.mobile/(b.pc+b.mobile),3) as p_mobile
from (
    select a.userid, sum(a.pc) as pc, sum(a.mobile) as mobile
    from (
        SELECT userid, (case when (p='pc') then pv else 0 end) as pc,
                       (case when (p='mobile') then pv else 0 end) as mobile
        FROM actionlog._pv_all_action1) as a
    group by a.userid) as b;

create table actionlog._pv_all_action3 engine = myisam
select userid, total_pv, round((cnt-rank+1)/cnt,2) as total_pv_percentile, pc, mobile, p_pc, p_mobile
from (SELECT userid, total_pv, pc, mobile, p_pc, p_mobile, @curRank := @curRank + 1 AS rank
      FROM actionlog._pv_all_action2, (SELECT @curRank := 0) r
      order by total_pv desc) as dt,
     (select count(distinct userid) as cnt from actionlog._pv_all_action2) as ct;


# 討論區PV與比例
create table actionlog._forum_action_201412 engine = myisam
SELECT userid, uri, date(time) as d, platform_type  FROM actionlog.action_201412 where userid <> '' and uri like '%/forum%';
create table actionlog._forum_action_201501 engine = myisam
SELECT userid, uri, date(time) as d, platform_type  FROM actionlog.action_201501 where userid <> '' and uri like '%/forum%';
create table actionlog._forum_action_201502 engine = myisam
SELECT userid, uri, date(time) as d, platform_type  FROM actionlog.action_201502 where userid <> '' and uri like '%/forum%';
create table actionlog._forum_action_201503 engine = myisam
SELECT userid, uri, date(time) as d, platform_type  FROM actionlog.action_201503 where userid <> '' and uri like '%/forum%';

create table actionlog._pv_forum_action_201412 engine = myisam
SELECT userid, d, platform_type, count(userid) as c FROM actionlog._forum_action_201412 group by userid, d, platform_type;
create table actionlog._pv_forum_action_201501 engine = myisam
SELECT userid, d, platform_type, count(userid) as c FROM actionlog._forum_action_201501 group by userid, d, platform_type;
create table actionlog._pv_forum_action_201502 engine = myisam
SELECT userid, d, platform_type, count(userid) as c FROM actionlog._forum_action_201502 group by userid, d, platform_type;
create table actionlog._pv_forum_action_201503 engine = myisam
SELECT userid, d, platform_type, count(userid) as c FROM actionlog._forum_action_201503 group by userid, d, platform_type;

create table actionlog._pv_forum_action engine = myisam SELECT * FROM actionlog._pv_forum_action_201412;
insert ignore into actionlog._pv_forum_action SELECT * FROM actionlog._pv_forum_action_201501;
insert ignore into actionlog._pv_forum_action SELECT * FROM actionlog._pv_forum_action_201502;
insert ignore into actionlog._pv_forum_action SELECT * FROM actionlog._pv_forum_action_201503;

create table actionlog._pv_forum_action1 engine = myisam
SELECT userid, sum(c) as forum_pv 
FROM actionlog._pv_forum_action
where d between subdate(now(),91) and now()
group by userid;

create table actionlog._pv_forum_action2 engine = myisam
select userid, forum_pv, round((cnt-rank+1)/cnt,2) as forum_pv_percentile
from (SELECT userid, forum_pv, @curRank := @curRank + 1 AS rank
      FROM actionlog._pv_forum_action1, (SELECT @curRank := 0) r
      order by forum_pv desc) as dt,
     (select count(distinct userid) as cnt from actionlog._pv_forum_action1) as ct;

        ALTER TABLE actionlog._pv_all_action3 ADD INDEX (`userid`);
        ALTER TABLE actionlog._pv_forum_action2 ADD INDEX (`userid`);

create table actionlog._pv_forum_action3_list1 engine = myisam
SELECT a.userid, b.forum_pv, a.forum_pv_percentile, a.total_pv, a.total_pv_percentile, a.pc, a.mobile, a.p_pc, a.p_mobile
FROM actionlog._pv_all_action3 a left join actionlog._pv_forum_action2 b on a.userid = b.userid
where a.total_pv_percentile > 0.49;

        ALTER TABLE actionlog._pv_forum_action3_list1 convert to character set utf8 collate utf8_general_ci;

create table actionlog._pv_forum_action3_list2 engine = myisam
SELECT a.userid, b.nickname, a.forum_pv, a.forum_pv_percentile, a.total_pv, a.total_pv_percentile, a.pc, a.mobile, a.p_pc, a.p_mobile
FROM actionlog._pv_forum_action3_list1 a left join plsport_playsport.member b on a.userid = b.userid;

# 每個人最後一次登入是何日
CREATE TABLE plsport_playsport._last_time_login engine = myisam
SELECT userid, date(max(signin_time)) as last_time_login
FROM plsport_playsport.member_signin_log_archive
GROUP BY userid;

        ALTER TABLE actionlog._pv_forum_action3_list2 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE plsport_playsport._last_time_login convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._pv_forum_action3_list2  ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._last_time_login ADD INDEX (`userid`);
        
create table actionlog._pv_forum_action3_list3 engine = myisam
SELECT a.userid, a.nickname, a.forum_pv, a.forum_pv_percentile, a.total_pv, a.total_pv_percentile, a.pc, a.mobile, a.p_pc, a.p_mobile, b.last_time_login
FROM actionlog._pv_forum_action3_list2 a left join plsport_playsport._last_time_login b on a.userid = b.userid;

create table plsport_playsport._pcash_log engine = myisam
SELECT userid, sum(amount) as spent
FROM plsport_playsport.pcash_log
where payed = 1 and type = 1
and date between subdate(now(),91) and now()
group by userid;

        ALTER TABLE plsport_playsport._pcash_log ADD INDEX (`userid`);
        ALTER TABLE actionlog._pv_forum_action3_list3 ADD INDEX (`userid`);

create table actionlog._pv_forum_action3_list4 engine = myisam
SELECT a.userid, a.nickname, a.forum_pv, a.forum_pv_percentile, a.total_pv, a.total_pv_percentile, b.spent, a.pc, a.mobile, a.p_pc, a.p_mobile, a.last_time_login
FROM actionlog._pv_forum_action3_list3 a left join plsport_playsport._pcash_log b on a.userid = b.userid;

SELECT 'userid', '暱稱', '討論區pv', '討論區pv前n%', '全站pv', '全站pv前n%', '購買預測金額', '電腦pv', '手機pv', '電腦%', '手機%', '最後登入時間' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/header_improve_MVP_list.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._pv_forum_action3_list4);



# =================================================================================================
# 任務: 雙料殺手漲價:帳戶信名單撈取 [新建] (柔雅) 2015-03-26
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4482&projectId=11
#  TO eddy:
# 麻煩協助撈取寄送帳戶信的名單，
# 
# 條件: 
# 1.殺手:目前有販售資格的殺手
# 2.消費者:近三個月內有以噱幣消費、且累積儲值達999元的人
# 
# 麻煩協助撈取名單，
# 時間:最晚3/26完成。
# =================================================================================================

create table plsport_playsport._medal_fire engine = myisam 
SELECT userid, nickname, count(userid) as c
FROM plsport_playsport.medal_fire
where sell_allow = 1
and vol > 100
group by userid, nickname;

create table plsport_playsport._single_killer engine = myisam 
SELECT userid, nickname, count(userid) as c 
FROM plsport_playsport.single_killer
where sell_allow =1
group by userid, nickname;

create table plsport_playsport._killer_list engine = myisam
SELECT * FROM plsport_playsport._medal_fire;
insert ignore into plsport_playsport._killer_list 
SELECT * FROM plsport_playsport._single_killer;

create table plsport_playsport._killer_list_1 engine = myisam
SELECT userid, nickname
FROM plsport_playsport._killer_list
group by userid, nickname;

create table plsport_playsport._buyer_list engine = myisam
select * 
from (
    select a.userid, sum(a.price) as total_spent
    from (
        SELECT userid, createon, price  
        FROM plsport_playsport.order_data
        where payway in (1,2,3,4,5,6,9,10)
        and sellconfirm = 1
        and createon between subdate(now(),91) and now()) as a
    group by a.userid) as b
where b.total_spent > 998;

create table plsport_playsport._buyer_list_1 engine = myisam
SELECT a.userid, a.total_spent, b.nickname
FROM plsport_playsport._buyer_list a left join plsport_playsport._killer_list_1 b on a.userid = b.userid
where b.nickname is null;

SELECT userid
into outfile 'C:/Users/1-7_ASUS/Desktop/_killer_list.txt'
fields terminated by ',' enclosed by '' lines terminated by '\r\n'
FROM plsport_playsport._killer_list_1;

SELECT userid
into outfile 'C:/Users/1-7_ASUS/Desktop/_buyer_list.txt'
fields terminated by ',' enclosed by '' lines terminated by '\r\n'
FROM plsport_playsport._buyer_list_1;


# =================================================================================================
# 任務: 2015年雙料殺手漲價 追蹤成果 [新建] (福利班 [管理員])
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4276&projectId=11
# 目的:調整雙料殺手售價，148元改為168元、特價128元改為148元。
# 上線時間: 3/30 開始(時間待確認)，全面調整售價。 
# 
# 必須追蹤以下：
# 各種殺手的購買佔比，單殺、莊殺、雙料，
# 和之前銀牌殺手價格調漲的內容一樣，
# 
# 追蹤區間
# 先抓了兩個月，3/30~ 5/30
# =================================================================================================

# 匯入 (1)predict_seller (2)alliance (3)order_data

create table plsport_playsport._predict_seller_with_medal engine = myisam
SELECT id, sellerid, mode, sale_allianceid, sale_gameid, sale_date, substr(sale_date,1,7) as m, substr(sale_date,1,10) as d, sale_price, buyer_count, rank, rank_sk, selltype,
       (case when (selltype = 1) then '莊殺'
             when (selltype = 2) then '單殺'
             when (selltype = 3) then '雙殺' end ) as killtype,
       (case when (rank <11 and selltype = 1) then '金牌'
             when (rank <31 and selltype = 1) then '銀牌'
             when (rank <52 and selltype = 1) then '銅牌'
             when (rank_sk< 11 and selltype = 2) then '金牌'
             when (rank_sk< 31 and selltype = 2) then '銀牌'
             when (rank_sk< 52 and selltype = 2) then '銅牌'
             when (rank < 11 and selltype = 3) then '金牌'
             when (rank_sk < 11 and selltype = 3) then '金牌' else '銀牌' end) as killmedal     
FROM plsport_playsport.predict_seller /*最好是指定精確的日期區間*/
where sale_date between '2011-12-15 00:00:00' and now(); /*<====記得要改*/

create table plsport_playsport._pcash_log engine = myisam
select userid, amount, date(date) as c_date, month(date) as c_month, year(date) as c_year, substr(date,1,7) as ym, id_this_type
from plsport_playsport.pcash_log
where payed = 1 and type = 1
and date between '2012-01-01 00:00:00' and now();

        ALTER TABLE  plsport_playsport._pcash_log ADD INDEX (`id_this_type`);       
        ALTER TABLE  plsport_playsport._predict_seller_with_medal ADD INDEX (`id`);
        ALTER TABLE  plsport_playsport.alliance ADD INDEX (`allianceid`);

create table plsport_playsport._pcash_log_with_detailed_info engine = myisam
select c.userid, c.amount, c.c_date, c.c_month, c.c_year, c.ym,
       c.id, c.sellerid, c.sale_allianceid, d.alliancename, c.sale_date, c.sale_price, c.killtype, c.killmedal
from (
    SELECT a.userid, a.amount, a.c_date, a.c_month, a.c_year, a.ym, 
           b.id, b.sellerid, b.sale_allianceid, b.sale_date, b.sale_price, b.killtype, b.killmedal
    FROM plsport_playsport._pcash_log a left join plsport_playsport._predict_seller_with_medal b on a.id_this_type = b.id) as c
left join plsport_playsport.alliance as d on c.sale_allianceid = d.allianceid;

create table plsport_playsport._pcash_log_with_detailed_info_1 engine = myisam
select a.c_date as d, a.killtype, count(a.userid) as buyer_count
from (
    SELECT * FROM plsport_playsport._pcash_log_with_detailed_info
    where sale_date between subdate(now(),62) and subdate(now(),1)) as a
group by a.c_date, a.killtype
order by a.c_date desc;

create table plsport_playsport._predict_seller_with_medal_1 engine = myisam
SELECT a.sellerid, a.sale_allianceid, b.alliancename, a.sale_gameid, a.sale_date, a.d, a.sale_price, a.killtype 
FROM plsport_playsport._predict_seller_with_medal a left join plsport_playsport.alliance b on a.sale_allianceid = b.allianceid;

create table plsport_playsport._predict_seller_with_medal_2 engine = myisam
SELECT sale_allianceid, alliancename, d, sale_price, killtype, count(sellerid) as seller_count 
FROM plsport_playsport._predict_seller_with_medal_1
group by sale_allianceid, alliancename, d, sale_price, killtype
order by d desc;

create table plsport_playsport._predict_seller_with_medal_3 engine = myisam
SELECT concat(sale_allianceid,'_',alliancename) as alliance, d, sale_price, killtype, seller_count
FROM plsport_playsport._predict_seller_with_medal_2;

create table plsport_playsport._predict_seller_with_medal_4 engine = myisam
SELECT d, killtype, sum(seller_count) as seller_count 
FROM plsport_playsport._predict_seller_with_medal_3
where d between subdate(now(),62) and subdate(now(),1)
group by d, killtype
order by d desc;

create table plsport_playsport._main_table_1 engine = myisam
select c.d as date, c.killtype, c.seller_count, c.buyer_count, round((c.buyer_count/c.seller_count),1) as ratio
from (
    SELECT a.d, a.killtype, a.seller_count, b.buyer_count
    FROM plsport_playsport._predict_seller_with_medal_4 a left join plsport_playsport._pcash_log_with_detailed_info_1 b on a.d = b.d and a.killtype = b.killtype) as c;

SELECT 'date', 'killtype', 'seller_count', 'buyer_count', 'ratio' union (
SELECT *
into outfile 'C:/proc/python/data/everyday_killer_type_stat.csv'
fields terminated by ',' enclosed by '' lines terminated by '\r\n'
FROM plsport_playsport._main_table_1);


# 以下的部分開始分析 2015-06-03

# 每天的販售數量

create table plsport_playsport.__sell_count_everyday engine = myisam
SELECT d, killtype, count(sellerid) as sell_count
FROM plsport_playsport._predict_seller_with_medal_1
where year(sale_date) > 2012
group by d, killtype;

SELECT 'date', 'killtype', 'sell_count' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/__sell_count_everyday.csv'
fields terminated by ',' enclosed by '' lines terminated by '\r\n'
FROM plsport_playsport.__sell_count_everyday);

select substr(b.ym,1,4) as y, substr(b.ym,6,2) as m, b.killtype, count(b.sellerid) as killer_count
from (
    select a.sellerid, a.ym, a.killtype
    from (
        SELECT sellerid, sale_date, substr(sale_date,1,7) as ym,  killtype 
        FROM plsport_playsport._predict_seller_with_medal_1) as a
    group by a.sellerid, a.ym, a.killtype) as b
group by b.ym, b.killtype;


create table plsport_playsport._pcash_log engine = myisam
select userid, amount, date(date) as c_date, month(date) as c_month, year(date) as c_year, substr(date,1,7) as ym, id_this_type
from plsport_playsport.pcash_log
where payed = 1 and type = 1
and date between '2013-01-01 00:00:00' and now();

        ALTER TABLE  plsport_playsport._pcash_log ADD INDEX (`id_this_type`);       
        ALTER TABLE  plsport_playsport._predict_seller_with_medal ADD INDEX (`id`);
        ALTER TABLE  plsport_playsport.alliance ADD INDEX (`allianceid`);

create table plsport_playsport._pcash_log_with_detailed_info engine = myisam
select c.userid, c.amount, c.c_date, c.c_month, c.c_year, c.ym,
       c.id, c.sellerid, c.sale_allianceid, d.alliancename, c.sale_date, c.sale_price, c.killtype, c.killmedal
from (
    SELECT a.userid, a.amount, a.c_date, a.c_month, a.c_year, a.ym, 
           b.id, b.sellerid, b.sale_allianceid, b.sale_date, b.sale_price, b.killtype, b.killmedal
    FROM plsport_playsport._pcash_log a left join plsport_playsport._predict_seller_with_medal b on a.id_this_type = b.id) as c
left join plsport_playsport.alliance as d on c.sale_allianceid = d.allianceid;


# 每月買牌的人數(用不到)
select a.ym, a.killtype, count(a.userid) as buyer_count
from (
    SELECT ym, killtype, userid, count(userid) as buyer_count
    FROM plsport_playsport._pcash_log_with_detailed_info
    group by ym, killtype, userid) as a
where a.killtype is not null
group by a.ym, a.killtype;

# 每月購買數
SELECT ym, killtype, count(sale_price) as buy_count 
FROM plsport_playsport._pcash_log_with_detailed_info
where killtype is not null
group by ym, killtype;


# 各價格帶每月的收益佔比%
SELECT ym, amount, sum(amount) as t 
FROM plsport_playsport._pcash_log_with_detailed_info
group by ym, amount;


# 每月各價值上架數
SELECT m, sale_price, count(sellerid) as c 
FROM plsport_playsport._predict_seller_with_medal
where year(sale_date)> 2012
group by m, sale_price;

# 開會討論後補充
# 各聯盟當選殺手人數, 只看NBA, 日棒, MLB

create table plsport_playsport.__sell_count_everyday_mlb engine = myisam
SELECT d, killtype, count(sellerid) as sell_count
FROM plsport_playsport._predict_seller_with_medal_1
where year(sale_date) > 2012
and sale_allianceid = 1
group by d, killtype;

create table plsport_playsport.__sell_count_everyday_jpb engine = myisam
SELECT d, killtype, count(sellerid) as sell_count
FROM plsport_playsport._predict_seller_with_medal_1
where year(sale_date) > 2012
and sale_allianceid = 2
group by d, killtype;

create table plsport_playsport.__sell_count_everyday_nba engine = myisam
SELECT d, killtype, count(sellerid) as sell_count
FROM plsport_playsport._predict_seller_with_medal_1
where year(sale_date) > 2012
and sale_allianceid = 3
group by d, killtype;


SELECT 'date', 'killtype', 'sell_count', 'year', 'month' union (
SELECT d, killtype, sell_count, year(d) as y, month(d) as m
into outfile 'C:/Users/1-7_ASUS/Desktop/__sell_count_everyday_mlb.csv'
fields terminated by ',' enclosed by '' lines terminated by '\r\n'
FROM plsport_playsport.__sell_count_everyday_mlb);

SELECT 'date', 'killtype', 'sell_count', 'year', 'month' union (
SELECT d, killtype, sell_count, year(d) as y, month(d) as m
into outfile 'C:/Users/1-7_ASUS/Desktop/__sell_count_everyday_jpb.csv'
fields terminated by ',' enclosed by '' lines terminated by '\r\n'
FROM plsport_playsport.__sell_count_everyday_jpb);

SELECT 'date', 'killtype', 'sell_count', 'year', 'month' union (
SELECT d, killtype, sell_count, year(d) as y, month(d) as m
into outfile 'C:/Users/1-7_ASUS/Desktop/__sell_count_everyday_nba.csv'
fields terminated by ',' enclosed by '' lines terminated by '\r\n'
FROM plsport_playsport.__sell_count_everyday_nba);


# 重新執行plsport_playsport._pcash_log_with_detailed_info


# 每月購買數
SELECT substr(ym,1,4) as y, substr(ym,6,2) as m, killtype, count(sale_price) as buy_count 
FROM plsport_playsport._pcash_log_with_detailed_info
where killtype is not null and sale_allianceid = 1
group by ym, killtype;

SELECT substr(ym,1,4) as y, substr(ym,6,2) as m, killtype, count(sale_price) as buy_count 
FROM plsport_playsport._pcash_log_with_detailed_info
where killtype is not null and sale_allianceid = 2
group by ym, killtype;

SELECT substr(ym,1,4) as y, substr(ym,6,2) as m, killtype, count(sale_price) as buy_count 
FROM plsport_playsport._pcash_log_with_detailed_info
where killtype is not null and sale_allianceid = 3
group by ym, killtype;

# 以價格來區分, 製作購買上架比
select b.ym, b.sale_price, b.sell_count
from (
    select a.ym, a.sale_price, count(a.sellerid) as sell_count
    from (
        SELECT substr(d,1,7) as ym, sale_price, sellerid
        FROM plsport_playsport._predict_seller_with_medal_1
        where year(sale_date) > 2013
        and sale_allianceid = 2) as a # 改allianceid即可 (1,2,3)
    group by a.ym, a.sale_price) as b;

SELECT ym, sale_price, count(sale_price) as buy_count 
FROM plsport_playsport._pcash_log_with_detailed_info
where  sale_allianceid = 2 and c_year > 2013
group by ym, sale_price;



# =================================================================================================
# 任務: [201412-G-3]文章列表改版-MVP測試名單撈取 [新建]
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4513&projectId=11
# 說明
# 提供MVP測試名單
# 
# 需求
#  
# - 撈取時間:近三個月
# - 需求欄位:暱稱、ID、討論區PV與比例(前40%)、電腦與手機使用比、最後登入時間
# =================================================================================================


create table actionlog._forum_log engine = myisam
SELECT userid, uri, time, (case when (platform_type<2) then 'pc' else 'mobile' end) as p
FROM actionlog.action_201501
where userid <> '' and uri like '%/forum%';
insert ignore into actionlog._forum_log 
SELECT userid, uri, time, (case when (platform_type<2) then 'pc' else 'mobile' end) as p
FROM actionlog.action_201502
where userid <> '' and uri like '%/forum%';
insert ignore into actionlog._forum_log 
SELECT userid, uri, time, (case when (platform_type<2) then 'pc' else 'mobile' end) as p
FROM actionlog.action_201503
where userid <> '' and uri like '%/forum%';
insert ignore into actionlog._forum_log 
SELECT userid, uri, time, (case when (platform_type<2) then 'pc' else 'mobile' end) as p
FROM actionlog.action_201504
where userid <> '' and uri like '%/forum%';

create table actionlog._forum_log_1 engine = myisam
SELECT * 
FROM actionlog._forum_log
where time between subdate(now(),91) and now();

create table actionlog._forum_log_2 engine = myisam
SELECT userid, p, count(uri) as c 
FROM actionlog._forum_log_1
group by userid, p;

create table actionlog._forum_log_3 engine = myisam
SELECT userid, (case when (p='pc') then c else 0 end) as pc,
               (case when (p='mobile') then c else 0 end) as mobile 
FROM actionlog._forum_log_2;

create table actionlog._forum_log_4 engine = myisam
SELECT userid, sum(pc) as pc, sum(mobile) as mobile 
FROM actionlog._forum_log_3
group by userid;

create table actionlog._forum_log_5 engine = myisam
SELECT userid, (pc+mobile) as pv, pc, mobile ,round((pc/(pc+mobile)),3) as p_pc, round((mobile/(pc+mobile)),3) as p_mobile
FROM actionlog._forum_log_4;

create table actionlog._forum_log_6 engine = myisam
select userid, pv, round((cnt-rank+1)/cnt,2) as pv_percentile, pc, mobile, p_pc, p_mobile
from (SELECT userid, pv, @curRank := @curRank + 1 AS rank, pc, mobile, p_pc, p_mobile
      FROM actionlog._forum_log_5, (SELECT @curRank := 0) r
      order by pv desc) as dt,
     (select count(distinct userid) as cnt from actionlog._forum_log_5) as ct;

        ALTER TABLE actionlog._forum_log_6 convert to character set utf8 collate utf8_general_ci;

create table actionlog._forum_log_7 engine = myisam
SELECT a.userid, b.nickname, a.pv, a.pv_percentile, a.pc, a.mobile, a.p_pc, a.p_mobile 
FROM actionlog._forum_log_6 a left join plsport_playsport.member b on a.userid = b.userid
where a.pv_percentile > 0.59;

# 每個人最後一次登入是何日
CREATE TABLE plsport_playsport._last_time_login engine = myisam
SELECT userid, date(max(signin_time)) as last_time_login
FROM plsport_playsport.member_signin_log_archive
GROUP BY userid;

        ALTER TABLE plsport_playsport._last_time_login convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._forum_log_7 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE plsport_playsport._last_time_login ADD INDEX (`userid`);
        ALTER TABLE actionlog._forum_log_7 ADD INDEX (`userid`);
        
create table actionlog._forum_log_8 engine = myisam
SELECT a.userid, a.nickname, a.pv, a.pv_percentile, a.pc, a.mobile, a.p_pc, a.p_mobile, b.last_time_login
FROM actionlog._forum_log_7 a left join plsport_playsport._last_time_login b on a.userid = b.userid;

SELECT 'userid', '暱稱', '討論區PV','討論區PV級距%','電腦pv','手機pv','電腦佔比%','手機佔比%', '最後登入時間' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_forum_log_8.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._forum_log_8);

# 暱稱、ID、討論區PV與比例(前40%)、電腦與手機使用比、最後登入時間



# =================================================================================================
# 任務: [201409-B-4] 棒球即時比分比賽過程網頁版 - MVP測試名單 [新建] (阿達) 2015-04-07
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4493&projectId=11
# 說明
# 提供此任務優化MVP測試名單
# 負責人：Eddy
# 時間：4/7(二)
# 內容
# 1. MVP測試名單
# 條件：今年MLB即時比分PV前50%
# 欄位：
# a. 帳號
# b. 暱稱
# c. 今年MLB即時比分pv及全站佔比
# d. 手機、電腦使用比例
# =================================================================================================

create table actionlog._livescore engine = myisam
SELECT userid, uri, time, (case when (platform_type<2) then 'pc' else 'mobile' end) as p
FROM actionlog.action_201501_with_userid
where uri like '%livescore.php%';
insert ignore into actionlog._livescore
SELECT userid, uri, time, (case when (platform_type<2) then 'pc' else 'mobile' end) as p
FROM actionlog.action_201502_with_userid
where uri like '%livescore.php%';
insert ignore into actionlog._livescore
SELECT userid, uri, time, (case when (platform_type<2) then 'pc' else 'mobile' end) as p
FROM actionlog.action_201503_with_userid
where uri like '%livescore.php%';
insert ignore into actionlog._livescore
SELECT userid, uri, time, (case when (platform_type<2) then 'pc' else 'mobile' end) as p
FROM actionlog.action_201504_with_userid
where uri like '%livescore.php%';

create table actionlog._livescore1 engine = myisam
SELECT * FROM actionlog._livescore
where userid <> '';

create table actionlog._livescore2 engine = myisam
SELECT userid, uri, time, p, (case when (locate('aid',uri)>0) then substr(uri, locate('aid=',uri)+4, length(uri)) else '' end) as aid
FROM actionlog._livescore1;

create table actionlog._livescore3 engine = myisam
SELECT userid, uri, time, p ,(case when (locate('&', aid)>0) then substr(aid,1,locate('&', aid)-1) else aid end) as aid
FROM actionlog._livescore2;


create table actionlog._livescore3_1 engine = myisam
SELECT * FROM actionlog._livescore3
where time between '2015-01-01 00:00:00' and '2015-03-31 23:59:59';

create table actionlog._livescore3_2 engine = myisam
SELECT * FROM actionlog._livescore3
where time between '2015-04-01 00:00:00' and '2015-04-31 23:59:59';

create table actionlog._livescore4_1 engine = myisam
SELECT userid, uri, time, p, (case when (aid='') then 3 else aid end) as aid 
FROM actionlog._livescore3_1;

create table actionlog._livescore4_2 engine = myisam
SELECT userid, uri, time, p, (case when (aid='') then 1 else aid end) as aid 
FROM actionlog._livescore3_2;


create table actionlog._livescore5 engine = myisam
SELECT * FROM actionlog._livescore4_1;
insert ignore into actionlog._livescore5
SELECT * FROM actionlog._livescore4_2;

create table actionlog._livescore6 engine = myisam
SELECT * FROM actionlog._livescore5
where aid = 1;

create table actionlog._livescore7 engine = myisam
select b.userid, sum(pc) as pc, sum(mobile) as mobile
from (
    select a.userid, (case when (a.p='pc') then pv else 0 end) as pc,
                     (case when (a.p='mobile') then pv else 0 end) as mobile
    from (
        SELECT userid, p, count(uri) as pv 
        FROM actionlog._livescore6
        group by userid, p) as a) as b
group by b.userid;

create table actionlog._livescore8 engine = myisam
SELECT userid, (pc+mobile) as pv, round((pc/(pc+mobile)),3) as p_pc, round((mobile/(pc+mobile)),3) as p_mobile
FROM actionlog._livescore7;


create table actionlog._livescore9 engine = myisam
select userid, pv, round((cnt-rank+1)/cnt,2) as pv_percentile, p_pc, p_mobile
from (SELECT userid, pv, @curRank := @curRank + 1 AS rank, p_pc, p_mobile
      FROM actionlog._livescore8, (SELECT @curRank := 0) r
      order by pv desc) as dt,
     (select count(distinct userid) as cnt from actionlog._livescore8) as ct;


# 最近一次的登入時間
CREATE TABLE plsport_playsport._last_login_time engine = myisam
SELECT userid, max(signin_time) as last_login
FROM plsport_playsport.member_signin_log_archive
GROUP BY userid;

        ALTER TABLE actionlog._livescore9 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._livescore9 ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._last_login_time convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE plsport_playsport._last_login_time ADD INDEX (`userid`);


create table actionlog._livescore10 engine = myisam
select c.userid, c.nickname, c.pv, c.pv_percentile, c.p_pc, c.p_mobile, date(d.last_login) as last_login
from (
    SELECT a.userid, b.nickname, a.pv, a.pv_percentile, a.p_pc, a.p_mobile 
    FROM actionlog._livescore9 a left join plsport_playsport.member b on a.userid = b.userid) as c
    left join plsport_playsport._last_login_time as d on c.userid = d.userid
where c.pv_percentile > 0.49;

SELECT '帳號', '暱稱', 'MLB即時比分pv', 'pv級距', '使用電腦比例', '使用手機比例', '最後登入' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_livescore10.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._livescore10);


# =================================================================================================
# 任務: 使用者投注習慣問卷-分析任務 [新建] 2015-04-20 (柔雅)
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4581&projectId=11
#  TO eddy:
# 
# 經由問卷，我們收集到使用者的投注習慣，
# 麻煩協助分析。
# 1.問卷問題的統計整理
# 2.試算，運彩盤一天大約可獲得多少注單。
# 問卷回覆的網址
# =================================================================================================

create table plsport_playsport._ans engine = myisam
SELECT a.mestamp, a.id, b.userid, a.bet, a.mode, a.q1, a.q2, a.q3, a.q4, a.q5, a.q6, a.q7, a.q8, a.q9, a.q10, a.q11
FROM plsport_playsport.ans a left join plsport_playsport.member b on a.id = b.id;

create table plsport_playsport._ans_1 engine = myisam
SELECT min(mestamp) as time, id, userid, bet, mode, q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11 
FROM plsport_playsport._ans
group by id;

create table plsport_playsport._ans_2 engine = myisam
SELECT min(mestamp) as time, id, userid, bet, mode, q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11 
FROM plsport_playsport._ans
where userid is not null
group by userid;


SELECT bet, mode, count(userid) as c
FROM plsport_playsport._ans_2
group by bet , mode;

# 有	兩者都有	1255
# 有	國際盤	    868
# 有	運彩盤	    1487
# 沒有		        491

create table plsport_playsport._ans_3_1 engine = myisam
SELECT q6, q7, q8, count(userid) as c 
FROM plsport_playsport._ans_2
where mode = '國際盤'
group by q6, q7, q8;

        update plsport_playsport._ans_3_1 set q7 = 'a_0~3000元'     where q7 = '0~3000元';
        update plsport_playsport._ans_3_1 set q7 = 'b_3001~9000元'  where q7 = '3001~9000元';
        update plsport_playsport._ans_3_1 set q7 = 'c_9001~15000元' where q7 = '9001~15000元';
        update plsport_playsport._ans_3_1 set q7 = 'd_15001~20000元'where q7 = '15001~20000元';
        update plsport_playsport._ans_3_1 set q7 = 'e_20001元以上'  where q7 = '20001元以上';

        update plsport_playsport._ans_3_1 set q8 = 'a_100~500元'   where q8 = '100~500元';
        update plsport_playsport._ans_3_1 set q8 = 'b_501~1000元'  where q8 = '501~1000元';
        update plsport_playsport._ans_3_1 set q8 = 'c_1001~2000元' where q8 = '1001~2000元';
        update plsport_playsport._ans_3_1 set q8 = 'd_2001~3000元' where q8 = '2001~3000元';
        update plsport_playsport._ans_3_1 set q8 = 'e_3001元以上'  where q8 = '3001元以上';

create table plsport_playsport._ans_3_2 engine = myisam
SELECT q9, q10, q11, count(userid) as c 
FROM plsport_playsport._ans_2
where mode = '運彩盤'
group by q9, q10, q11;

        update plsport_playsport._ans_3_2 set q10 = 'a_0~1000元'     where q10 = '0~1000元';
        update plsport_playsport._ans_3_2 set q10 = 'b_1001~3000元'  where q10 = '1001~3000元';
        update plsport_playsport._ans_3_2 set q10 = 'c_3001~6000元'  where q10 = '3001~6000元';
        update plsport_playsport._ans_3_2 set q10 = 'd_6001~10000元' where q10 = '6001~10000元';
        update plsport_playsport._ans_3_2 set q10 = 'e_10001元以上'  where q10 = '10001元以上';

        update plsport_playsport._ans_3_2 set q11 = 'a_100~500元'   where q11 = '100~500元';
        update plsport_playsport._ans_3_2 set q11 = 'b_500~1000元'  where q11 = '500~1000元';
        update plsport_playsport._ans_3_2 set q11 = 'c_1000~2000元' where q11 = '1000~2000元';
        update plsport_playsport._ans_3_2 set q11 = 'd_2001~3000元' where q11 = '2001~3000元';
        update plsport_playsport._ans_3_2 set q11 = 'e_3001元以上'  where q11 = '3001元以上';

create table plsport_playsport._ans_3_3 engine = myisam
SELECT * FROM plsport_playsport._ans_2
where mode = '兩者都有';

        update plsport_playsport._ans_3_3 set q2 = 'a_0~3000元'     where q2 = '0~3000元';
        update plsport_playsport._ans_3_3 set q2 = 'b_3001~9000元'  where q2 = '3001~9000元';
        update plsport_playsport._ans_3_3 set q2 = 'c_9001~15000元' where q2 = '9001~15000元';
        update plsport_playsport._ans_3_3 set q2 = 'd_15001~20000元'where q2 = '15001~20000元';
        update plsport_playsport._ans_3_3 set q2 = 'e_20001元以上'  where q2 = '20001元以上';

        update plsport_playsport._ans_3_3 set q3 = 'a_100~500元'   where q3 = '100~500元';
        update plsport_playsport._ans_3_3 set q3 = 'b_501~1000元'  where q3 = '501~1000元';
        update plsport_playsport._ans_3_3 set q3 = 'c_1001~2000元' where q3 = '1001~2000元';
        update plsport_playsport._ans_3_3 set q3 = 'd_2001~3000元' where q3 = '2001~3000元';
        update plsport_playsport._ans_3_3 set q3 = 'e_3001元以上'  where q3 = '3001元以上';

        update plsport_playsport._ans_3_3 set q4 = 'a_0~1000元'     where q4 = '0~1000元';
        update plsport_playsport._ans_3_3 set q4 = 'b_1001~3000元'  where q4 = '1001~3000元';
        update plsport_playsport._ans_3_3 set q4 = 'c_3001~6000元'  where q4 = '3001~6000元';
        update plsport_playsport._ans_3_3 set q4 = 'd_6001~10000元' where q4 = '6001~10000元';
        update plsport_playsport._ans_3_3 set q4 = 'e_10001元以上'  where q4 = '10001元以上';

        update plsport_playsport._ans_3_3 set q5 = 'a_100~500元'   where q5 = '100~500元';
        update plsport_playsport._ans_3_3 set q5 = 'b_501~1000元'  where q5 = '501~1000元';
        update plsport_playsport._ans_3_3 set q5 = 'c_1001~2000元' where q5 = '1001~2000元';
        update plsport_playsport._ans_3_3 set q5 = 'd_2001~3000元' where q5 = '2001~3000元';
        update plsport_playsport._ans_3_3 set q5 = 'e_3001元以上'  where q5 = '3001元以上';

SELECT q1, q2, q3, count(userid) as c 
FROM plsport_playsport._ans_3_3
group by q1, q2, q3;

SELECT q1, q4, q5, count(userid) as c 
FROM plsport_playsport._ans_3_3
group by q1, q4, q5;

create table plsport_playsport._member_signin_log_archive engine = myisam
SELECT userid, date(signin_time) as d
FROM plsport_playsport.member_signin_log_archive
where year(signin_time) = 2015;

create table plsport_playsport._member_signin_log_archive_1 engine = myisam
SELECT userid, d, count(userid) 
FROM plsport_playsport._member_signin_log_archive
group by userid, d;

create table plsport_playsport._member_signin_log_archive_2 engine = myisam
SELECT d, count(userid) as c 
FROM plsport_playsport._member_signin_log_archive_1
group by d desc;


# =================================================================================================
# 任務: [201404-B-8]手機網頁版header優化-ABtesting報告 [新建] 2015-04-24 (靜怡)
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4563&projectId=11
# 說明
# 目的：了解新的手機網頁版header使用者是否喜歡
# 內容
# - 測試時間：4/17~5/8
# - 提供測試組
# - 觀察指標
#     版標以上的各連結點擊次數
#     頭三標的點擊與購買金額
#     總儲值金額
# - 報告時間：5/12
# EDDY
# 詳細事件設定請參考http://pm.playsport.cc/index.php/tasksComments?projectId=11&tasksId=4551
# =================================================================================================

# 檢查abtesting分組情況
# 分組名單 (userid%20)+1 in (1,2,3,4,5,6,7,8,9,10), 共50%的流量

# ABtesting重新上線
# 測試時間:4/23~5/21
# 報告:5/25

# 05-22 update: 開始分析

create table actionlog._check_HT_click engine = myisam
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201504
where uri like '%rp=HT_%' and userid <> ''
and time between '2015-04-24 16:00:00' and now(); #壯兔已經修正平版誤擊後的時間, 和event的事件也都修正了

insert ignore into actionlog._check_HT_click
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201505
where uri like '%rp=HT_%' and userid <> ''
and time between '2015-04-24 16:00:00' and now(); 

create table actionlog._check_HT_click_1 engine = myisam
SELECT userid, uri, time, platform_type, substr(uri,locate('&rp=',uri)+4,length(uri)) as ht
FROM actionlog._check_ht_click;

create table actionlog._check_HT_click_2 engine = myisam
SELECT userid, uri, time, platform_type, (case when (locate('&',ht)=0) then ht else substr(ht,1,locate('&',ht)-1) end ) as ht
FROM actionlog._check_ht_click_1;

SELECT  platform_type, ht, count(userid) as c
FROM actionlog._check_ht_click_2
where substr(ht,1,3) = 'HT_' and userid <> ''
group by platform_type, ht;

create table plsport_playsport._events engine = myisam
SELECT * FROM plsport_playsport.events
where name like '%header%'
and time between '2015-04-24 16:00:00' and now();

create table plsport_playsport._events_1 engine = myisam
select c.g, (case when (c.g<11) then 'A' else 'B' end) as abtest, c.userid, c.name, c.time
from (
    SELECT (b.id%20)+1 as g, a.userid, a.name, a.time 
    FROM plsport_playsport._events a left join plsport_playsport.member b on a.userid = b.userid) as c;

create table plsport_playsport._events_2 engine = myisam
SELECT g, abtest, userid, name, substr(name,8,1) as abtest_g, time 
FROM plsport_playsport._events_1;

SELECT abtest, abtest_g, count(g) 
FROM plsport_playsport._events_2
group by abtest, abtest_g;

# HT_D1	    電腦版-左標
# HT_D2	    電腦版-中標
# HT_D3	    電腦版-右標
# HT_M1A	手機版-新版-跑馬燈1
# HT_M2A	手機版-新版-跑馬燈2
# HT_M3A	手機版-新版-跑馬燈3
# HT_M1B	手機版-原版-左標
# HT_M2B	手機版-原版-中標
# HT_M3B	手機版-原版-右標

# A	A	974606
# A	B	260
# B	A	1756
# B	B	974614



# 先來檢查手機頭3標的點擊情況
create table actionlog._check_ht_click_3 engine = myisam
SELECT userid, uri, time, platform_type, ht, substr(ht,5,1) as abtest
FROM actionlog._check_ht_click_2
where platform_type = 2 and substr(ht,1,4) = 'HT_M';


# 算出點擊的名單(t-test)
SELECT 'abtest','userid', 'ht3_hit' union (
SELECT abtest, userid, count(ht) as ht3_hit
into outfile 'C:/Users/1-7_ASUS/Desktop/ht3_hit_user_list.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._check_ht_click_3
group by abtest, userid);


create table plsport_playsport._events_2_for_ht engine = myisam
select a.g, a.abtest, a.userid, a.name, a.abtest_g, a.time, concat(a.abtest,'_',a.abtest_g) as c, a.h
from (
    SELECT g, abtest, userid, name, abtest_g, (case when (substr(name,10,1)='h') then 1 else 0 end) as h, time 
    FROM plsport_playsport._events_2) as a;


select a.abtest, count(a.userid) as user_count
from (
    SELECT userid, abtest, count(name) as c
    FROM plsport_playsport._events_2_for_ht
    where c in ('A_A', 'B_B') and userid <> ''
    group by userid) as a
group by a.abtest;

# A	5883
# B	5816

select a.abtest, count(a.userid) as user_count
from (
    SELECT userid, abtest, count(name) as c
    FROM plsport_playsport._events_2_for_ht
    where c in ('A_A', 'B_B') and userid <> '' and h = 1 # 有點擊過版標的人
    group by userid) as a
group by a.abtest;

# A	2410
# B	2324

# A	5883 > 2410 (41%)
# B	5816 > 2324 (40%) Test "A" converted 3% better than Test "B." We are 87% 
#                     certain that the changes in Test "A" will improve your conversion rate.

create table plsport_playsport._events_2_for_position engine = myisam
SELECT g, abtest, userid, name, abtest_g, time, c, h, substr(name,10,2) as p 
FROM plsport_playsport._events_2_for_ht
where h = 0 and c in ('A_A','B_B');

# 每個版標位置的點擊數
SELECT abtest, p, count(name) as c 
FROM plsport_playsport._events_2_for_position
group by abtest, p;


# 討論區和找高手的流量有變少嗎?
# http://www.playsport.cc/forum.php
# http://www.playsport.cc/buy_predict.php

create table actionlog._forum engine = myisam
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201504
where uri like '%forum.php%' and userid <> ''
and time between '2015-04-24 16:00:00' and now(); 
insert ignore into actionlog._forum
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201505
where uri like '%forum.php%' and userid <> ''
and time between '2015-04-24 16:00:00' and now(); 

create table actionlog._buypredict engine = myisam
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201504
where uri like '%buy_predict.php%' and userid <> ''
and time between '2015-04-24 16:00:00' and now(); 
insert ignore into actionlog._buypredict
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201505
where uri like '%buy_predict.php%' and userid <> ''
and time between '2015-04-24 16:00:00' and now(); 

create table actionlog._usersearch engine = myisam
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201504
where uri like '%usersearch.php%' and userid <> ''
and time between '2015-04-24 16:00:00' and now(); 
insert ignore into actionlog._usersearch
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201505
where uri like '%usersearch.php%' and userid <> ''
and time between '2015-04-24 16:00:00' and now(); 


        ALTER TABLE actionlog._forum convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._buypredict convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._usersearch convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._forum  ADD INDEX (`userid`);
        ALTER TABLE actionlog._buypredict ADD INDEX (`userid`);
        ALTER TABLE actionlog._usersearch ADD INDEX (`userid`);


create table actionlog._forum_1 engine = myisam
SELECT b.id, a.userid, a.uri, a.time, a.platform_type 
FROM actionlog._forum a left join plsport_playsport.member b on a.userid = b.userid 
where platform_type = 2;

create table actionlog._buypredict_1 engine = myisam
SELECT b.id, a.userid, a.uri, a.time, a.platform_type 
FROM actionlog._buypredict a left join plsport_playsport.member b on a.userid = b.userid 
where platform_type = 2;

create table actionlog._usersearch_1 engine = myisam
SELECT b.id, a.userid, a.uri, a.time, a.platform_type 
FROM actionlog._usersearch a left join plsport_playsport.member b on a.userid = b.userid 
where platform_type = 2;

create table actionlog._forum_2 engine = myisam
select a.g, a.userid, count(uri) as forum_pv
from (
    SELECT (case when ((id%20)+1 <11) then 'a' else 'b' end) as g, userid, uri, time, platform_type
    FROM actionlog._forum_1) as a
group by a.g, a.userid;

create table actionlog._buypredict_2 engine = myisam
select a.g, a.userid, count(uri) as buypredict_pv
from (
    SELECT (case when ((id%20)+1 <11) then 'a' else 'b' end) as g, userid, uri, time, platform_type
    FROM actionlog._buypredict_1) as a
group by a.g, a.userid;

create table actionlog._usersearch_2 engine = myisam
select a.g, a.userid, count(uri) as usersearch_pv
from (
    SELECT (case when ((id%20)+1 <11) then 'a' else 'b' end) as g, userid, uri, time, platform_type
    FROM actionlog._usersearch_1) as a
group by a.g, a.userid;


SELECT 'abtest', 'userid', 'forum_pv' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/forum_pv.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._forum_2);

SELECT 'abtest', 'userid', 'buypredict_pv' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/buypredict_pv.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._buypredict_2);

SELECT 'abtest', 'userid', 'usersearch_pv' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/usersearch_pv.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._usersearch_2);



# a/b 2組的收益有不同嗎?

# 總儲值金額
create table plsport_playsport._order_data_mobile engine = myisam 
select a.userid, sum(a.price) as total_redeem
from (
    SELECT userid, createon, price, payway, platform_type
    FROM plsport_playsport.order_data
    where sellconfirm = 1
    and createon between '2015-04-24 16:00:00' and now()
    and platform_type = 2) as a
group by a.userid;

create table plsport_playsport._order_data_mobile_1 engine = myisam
SELECT (case when (((b.id%20)+1) < 11) then 'a' else 'b' end) as abtest , a.userid, a.total_redeem 
FROM plsport_playsport._order_data_mobile a left join plsport_playsport.member b on a.userid = b.userid;

SELECT 'abtest', 'userid', 'total_redeem' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/redeem.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._order_data_mobile_1);



create table plsport_playsport._ht3_revenue engine = myisam
SELECT buyerid, buy_date, buy_price, position, cons, substr(position,5,1) as abtest
FROM plsport_playsport._predict_buyer_with_cons
where buy_date between '2015-04-24 16:00:00' and now()
and substr(position,1,4) = 'HT_M';

create table plsport_playsport._ht3_revenue_1 engine = myisam
SELECT abtest, buyerid as userid, sum(buy_price) as reveune 
FROM plsport_playsport._ht3_revenue
group by abtest, buyerid;

SELECT 'abtest', 'userid', 'reveune' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/ht3_revenue.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._ht3_revenue_1);














# =================================================================================================
# 任務: 撈取亮單文相關數據 [新建] (學文) 2015-04-28
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4637&projectId=11
# 要麻煩您撈近一年的
# 1.每日有觀看討論區的會員數 (可以補上每日發文的會員數)
# 2.每日有發表亮單文的會員數
# 3.每日量討論區貼文數量
# 4.每日亮單文數量
# 麻煩您了!
# 再麻煩您押個時間唷謝謝
# =================================================================================================

# 計算每日有觀看討論區的會員數
create table actionlog._forum_201403 engine = myisam SELECT userid, uri, time FROM actionlog.action_201403 where uri like '%forumdetail.php%' and userid <> '';
create table actionlog._forum_201404 engine = myisam SELECT userid, uri, time FROM actionlog.action_201404 where uri like '%forumdetail.php%' and userid <> '';
create table actionlog._forum_201405 engine = myisam SELECT userid, uri, time FROM actionlog.action_201405 where uri like '%forumdetail.php%' and userid <> '';
create table actionlog._forum_201406 engine = myisam SELECT userid, uri, time FROM actionlog.action_201406 where uri like '%forumdetail.php%' and userid <> '';
create table actionlog._forum_201407 engine = myisam SELECT userid, uri, time FROM actionlog.action_201407 where uri like '%forumdetail.php%' and userid <> '';
create table actionlog._forum_201408 engine = myisam SELECT userid, uri, time FROM actionlog.action_201408 where uri like '%forumdetail.php%' and userid <> '';
create table actionlog._forum_201409 engine = myisam SELECT userid, uri, time FROM actionlog.action_201409 where uri like '%forumdetail.php%' and userid <> '';
create table actionlog._forum_201410 engine = myisam SELECT userid, uri, time FROM actionlog.action_201410 where uri like '%forumdetail.php%' and userid <> '';
create table actionlog._forum_201411 engine = myisam SELECT userid, uri, time FROM actionlog.action_201411 where uri like '%forumdetail.php%' and userid <> '';
create table actionlog._forum_201412 engine = myisam SELECT userid, uri, time FROM actionlog.action_201412 where uri like '%forumdetail.php%' and userid <> '';
create table actionlog._forum_201501 engine = myisam SELECT userid, uri, time FROM actionlog.action_201501 where uri like '%forumdetail.php%' and userid <> '';
create table actionlog._forum_201502 engine = myisam SELECT userid, uri, time FROM actionlog.action_201502 where uri like '%forumdetail.php%' and userid <> '';
create table actionlog._forum_201503 engine = myisam SELECT userid, uri, time FROM actionlog.action_201503 where uri like '%forumdetail.php%' and userid <> '';
create table actionlog._forum_201504 engine = myisam SELECT userid, uri, time FROM actionlog.action_201504 where uri like '%forumdetail.php%' and userid <> '';


create table actionlog._forum1_201403 engine = myisam select a.d, a.userid from ( SELECT userid, uri, date(time) as d FROM actionlog._forum_201403) as a group by a.d, a.userid;
create table actionlog._forum1_201404 engine = myisam select a.d, a.userid from ( SELECT userid, uri, date(time) as d FROM actionlog._forum_201404) as a group by a.d, a.userid;
create table actionlog._forum1_201405 engine = myisam select a.d, a.userid from ( SELECT userid, uri, date(time) as d FROM actionlog._forum_201405) as a group by a.d, a.userid;
create table actionlog._forum1_201406 engine = myisam select a.d, a.userid from ( SELECT userid, uri, date(time) as d FROM actionlog._forum_201406) as a group by a.d, a.userid;
create table actionlog._forum1_201407 engine = myisam select a.d, a.userid from ( SELECT userid, uri, date(time) as d FROM actionlog._forum_201407) as a group by a.d, a.userid;
create table actionlog._forum1_201408 engine = myisam select a.d, a.userid from ( SELECT userid, uri, date(time) as d FROM actionlog._forum_201408) as a group by a.d, a.userid;
create table actionlog._forum1_201409 engine = myisam select a.d, a.userid from ( SELECT userid, uri, date(time) as d FROM actionlog._forum_201409) as a group by a.d, a.userid;
create table actionlog._forum1_201410 engine = myisam select a.d, a.userid from ( SELECT userid, uri, date(time) as d FROM actionlog._forum_201410) as a group by a.d, a.userid;
create table actionlog._forum1_201411 engine = myisam select a.d, a.userid from ( SELECT userid, uri, date(time) as d FROM actionlog._forum_201411) as a group by a.d, a.userid;
create table actionlog._forum1_201412 engine = myisam select a.d, a.userid from ( SELECT userid, uri, date(time) as d FROM actionlog._forum_201412) as a group by a.d, a.userid;
create table actionlog._forum1_201501 engine = myisam select a.d, a.userid from ( SELECT userid, uri, date(time) as d FROM actionlog._forum_201501) as a group by a.d, a.userid;
create table actionlog._forum1_201502 engine = myisam select a.d, a.userid from ( SELECT userid, uri, date(time) as d FROM actionlog._forum_201502) as a group by a.d, a.userid;
create table actionlog._forum1_201503 engine = myisam select a.d, a.userid from ( SELECT userid, uri, date(time) as d FROM actionlog._forum_201503) as a group by a.d, a.userid;
create table actionlog._forum1_201504 engine = myisam select a.d, a.userid from ( SELECT userid, uri, date(time) as d FROM actionlog._forum_201504) as a group by a.d, a.userid;


create table actionlog._forum2 engine = myisam SELECT d, count(userid) as user_count FROM actionlog._forum1_201403 group by d;
insert ignore into actionlog._forum2 SELECT d, count(userid) as user_count FROM actionlog._forum1_201404 group by d;
insert ignore into actionlog._forum2 SELECT d, count(userid) as user_count FROM actionlog._forum1_201405 group by d;
insert ignore into actionlog._forum2 SELECT d, count(userid) as user_count FROM actionlog._forum1_201406 group by d;
insert ignore into actionlog._forum2 SELECT d, count(userid) as user_count FROM actionlog._forum1_201407 group by d;
insert ignore into actionlog._forum2 SELECT d, count(userid) as user_count FROM actionlog._forum1_201408 group by d;
insert ignore into actionlog._forum2 SELECT d, count(userid) as user_count FROM actionlog._forum1_201409 group by d;
insert ignore into actionlog._forum2 SELECT d, count(userid) as user_count FROM actionlog._forum1_201410 group by d;
insert ignore into actionlog._forum2 SELECT d, count(userid) as user_count FROM actionlog._forum1_201411 group by d;
insert ignore into actionlog._forum2 SELECT d, count(userid) as user_count FROM actionlog._forum1_201412 group by d;
insert ignore into actionlog._forum2 SELECT d, count(userid) as user_count FROM actionlog._forum1_201501 group by d;
insert ignore into actionlog._forum2 SELECT d, count(userid) as user_count FROM actionlog._forum1_201502 group by d;
insert ignore into actionlog._forum2 SELECT d, count(userid) as user_count FROM actionlog._forum1_201503 group by d;
insert ignore into actionlog._forum2 SELECT d, count(userid) as user_count FROM actionlog._forum1_201504 group by d;


# 計算每日上站的會員
create table plsport_playsport._member_signin_log_archive engine = myisam
SELECT userid, date(signin_time) as d
FROM plsport_playsport.member_signin_log_archive
where year(signin_time)>2013;

create table plsport_playsport._member_signin_log_archive_1 engine = myisam
SELECT userid, d
FROM plsport_playsport._member_signin_log_archive
group by userid, d;

create table plsport_playsport._member_signin_log_archive_2 engine = myisam
SELECT d, count(userid) as user_login 
FROM plsport_playsport._member_signin_log_archive_1
group by d;

# 亮單文人數
create table plsport_playsport._showoff_post engine = myisam
SELECT subjectid, postuser, date(posttime) as d
FROM plsport_playsport.forum
where gametype = 3 and year(posttime)>2013;

create table plsport_playsport._showoff_post_1 engine = myisam
SELECT postuser, d 
FROM plsport_playsport._showoff_post
group by postuser, d;

create table plsport_playsport._showoff_post_2 engine = myisam
SELECT d, count(postuser) as showoff_user_count 
FROM plsport_playsport._showoff_post_1
group by d;

# 每日貼文會員數
create table plsport_playsport._post_user_count engine = myisam
select a.d, a.postuser
from (
    SELECT subjectid, postuser, date(posttime) as d 
    FROM plsport_playsport.forum
    where year(posttime)>2013) as a
group by a.d, a.postuser;

create table plsport_playsport._post_user_count_1 engine = myisam
SELECT d, count(postuser) as post_user_count 
FROM plsport_playsport._post_user_count
group by d;

# 貼文數
create table plsport_playsport._post_count engine = myisam
select a.d, count(a.subjectid) as post_count
from (
    SELECT subjectid, postuser, date(posttime) as d 
    FROM plsport_playsport.forum
    where year(posttime)>2013) as a
group by a.d;

select a.m, sum(a.post_count)
from (
    SELECT substr(d,1,7) as m, post_count 
    FROM plsport_playsport._post_count) as a
group by a.m;

# 亮單文數
create table plsport_playsport._showoff_post_count engine = myisam
select a.d, count(a.subjectid) as show_post_count
from (
    SELECT subjectid, postuser, date(posttime) as d 
    FROM plsport_playsport.forum
    where year(posttime)>2013 and gametype = 3) as a
group by a.d;

create table plsport_playsport._list_1 engine = myisam
SELECT a.d, a.user_login, b.post_user_count
FROM plsport_playsport._member_signin_log_archive_2 a left join plsport_playsport._post_user_count_1 b on a.d = b.d;

create table plsport_playsport._list_2 engine = myisam
SELECT a.d, a.user_login, a.post_user_count, b.showoff_user_count
FROM plsport_playsport._list_1 a left join plsport_playsport._showoff_post_2 b on a.d = b.d;

create table plsport_playsport._list_3 engine = myisam
SELECT a.d, a.user_login, a.post_user_count, a.showoff_user_count, b.post_count
FROM plsport_playsport._list_2 a left join plsport_playsport._post_count b on a.d = b.d;

create table plsport_playsport._list_4 engine = myisam
SELECT a.d, a.user_login, a.post_user_count, a.showoff_user_count, a.post_count, b.show_post_count
FROM plsport_playsport._list_3 a left join plsport_playsport._showoff_post_count b on a.d = b.d;

create table plsport_playsport._list_5 engine = myisam
SELECT a.d, a.user_login, b.user_count as see_forum_user_count, a.post_user_count, a.showoff_user_count, a.post_count, a.show_post_count
FROM plsport_playsport._list_4 a left join actionlog._forum2 b on a.d = b.d
where a.d > '2014-03-31'
order by a.d;

SELECT 'd', 'user', 'see_forum', 'post_user', 'show_user', 'post_count', 'show_count'union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_list_5.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._list_5);



# =================================================================================================
# 任務: [201505-A-1] 消費者訪談 - 撈取訪談名單 [新建] 2015-05-06 (阿達)
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4688&projectId=11
# 撈取訪談名單
# 負責人：Eddy 
# 時間：5/7 (四)
# 
# 內容
# 1. 訪談名單
# 時間：近三個月
# 條件：
# - 近三個月站內消費額或儲值噱幣於前 50%
# 欄位：帳號、暱稱、網站登入天數、站內總消費額、近一個月站內消費額、近三個月站內消費額、手機電腦使用比例、最近上站日、居住地
# =================================================================================================

create table actionlog._action_log_201504 engine = myisam SELECT userid, uri, time, platform_type FROM actionlog.action_201504 where userid <> ''; # it takes 477 secs
create table actionlog._action_log_201505 engine = myisam SELECT userid, uri, time, platform_type FROM actionlog.action_201505 where userid <> ''; # it takes 494 secs
create table actionlog._action_log_201506 engine = myisam SELECT userid, uri, time, platform_type FROM actionlog.action_201506 where userid <> ''; # it takes 480 secs
create table actionlog._action_log_201507 engine = myisam SELECT userid, uri, time, platform_type FROM actionlog.action_201507 where userid <> ''; # it takes 290 secs
create table actionlog._action_log_201508 engine = myisam SELECT userid, uri, time, platform_type FROM actionlog.action_201508 where userid <> ''; # it takes 290 secs

create table actionlog.__action_log_201504 engine = myisam
SELECT userid, platform_type, count(uri) as pv FROM actionlog._action_log_201504 group by userid, platform_type;
create table actionlog.__action_log_201505 engine = myisam
SELECT userid, platform_type, count(uri) as pv FROM actionlog._action_log_201505 group by userid, platform_type;
create table actionlog.__action_log_201506 engine = myisam
SELECT userid, platform_type, count(uri) as pv FROM actionlog._action_log_201506 group by userid, platform_type;
create table actionlog.__action_log_201507 engine = myisam
SELECT userid, platform_type, count(uri) as pv FROM actionlog._action_log_201507 group by userid, platform_type;
create table actionlog.__action_log_201508 engine = myisam
SELECT userid, platform_type, count(uri) as pv FROM actionlog._action_log_201508 group by userid, platform_type;

update actionlog.__action_log_201504 set platform_type=2 where platform_type=3;
update actionlog.__action_log_201505 set platform_type=2 where platform_type=3;
update actionlog.__action_log_201506 set platform_type=2 where platform_type=3;
update actionlog.__action_log_201507 set platform_type=2 where platform_type=3;
update actionlog.__action_log_201508 set platform_type=2 where platform_type=3;

create table actionlog.___action_log engine = myisam select * from actionlog.__action_log_201505;
insert ignore into actionlog.___action_log select * from actionlog.__action_log_201506;
insert ignore into actionlog.___action_log select * from actionlog.__action_log_201507;
insert ignore into actionlog.___action_log select * from actionlog.__action_log_201508;


create table actionlog._action_log2_devices engine = myisam
select b.userid, round((b.pc/(b.pc+b.mobile)),3) as p_pc, round((b.mobile/(b.pc+b.mobile)),3) as p_mobile
from (
    select a.userid, sum(a.pc) as pc, sum(a.mobile) as mobile
    from (
        SELECT userid, (case when (platform_type=1) then pv else 0 end) as pc, (case when (platform_type=2) then pv else 0 end) as mobile
        FROM actionlog.___action_log) as a
    group by a.userid) as b;

create table actionlog._action_log1_201504 engine = myisam
select a.userid, a.d
from (
    SELECT userid, date(time) as d 
    FROM actionlog._action_log_201504) as a
group by a.userid, a.d;

create table actionlog._action_log1_201505 engine = myisam
select a.userid, a.d
from (
    SELECT userid, date(time) as d 
    FROM actionlog._action_log_201505) as a
group by a.userid, a.d;

create table actionlog._action_log1_201506 engine = myisam
select a.userid, a.d
from (
    SELECT userid, date(time) as d 
    FROM actionlog._action_log_201506) as a
group by a.userid, a.d;

create table actionlog._action_log1_201507 engine = myisam
select a.userid, a.d
from (
    SELECT userid, date(time) as d 
    FROM actionlog._action_log_201507) as a
group by a.userid, a.d;

create table actionlog._action_log1_201508 engine = myisam
select a.userid, a.d
from (
    SELECT userid, date(time) as d 
    FROM actionlog._action_log_201508) as a
group by a.userid, a.d;
# it takes 460 secs
# it takes 491 secs
# it takes 514 secs
# it takes 430 secs
# it takes 175 secs

create table actionlog._action_log1_day_count engine = myisam SELECT * FROM actionlog._action_log1_201505;
insert ignore into actionlog._action_log1_day_count select * from actionlog._action_log1_201506;
insert ignore into actionlog._action_log1_day_count select * from actionlog._action_log1_201507;
insert ignore into actionlog._action_log1_day_count select * from actionlog._action_log1_201508;

create table actionlog._action_log2_day_count engine = myisam
SELECT userid, count(d) as day_count
FROM actionlog._action_log1_day_count
where d between subdate(now(),90) and now()
group by userid;

# 最近一次的登入時間
CREATE TABLE plsport_playsport._last_login_time engine = myisam
SELECT userid, max(signin_time) as last_login
FROM plsport_playsport.member_signin_log_archive
GROUP BY userid;

# 站內總消費額
create table plsport_playsport._spent_all engine = myisam
SELECT userid, sum(amount) as total_spent
FROM plsport_playsport.pcash_log
where payed = 1 and type = 1
group by userid;

# 近一個月站內消費額
create table plsport_playsport._spent_one_month engine = myisam
SELECT userid, sum(amount) as one_month_spent
FROM plsport_playsport.pcash_log
where payed = 1 and type = 1
and date between subdate(now(),30) and now()
group by userid;

# 近三個月站內消費額
create table plsport_playsport._spent_three_month engine = myisam
SELECT userid, sum(amount) as three_month_spent
FROM plsport_playsport.pcash_log
where payed = 1 and type = 1
and date between subdate(now(),90) and now()
group by userid;

# 跑居住地 產出_user_city

ALTER TABLE actionlog._action_log2_devices convert to character set utf8 collate utf8_general_ci;
ALTER TABLE actionlog._action_log2_day_count convert to character set utf8 collate utf8_general_ci;
ALTER TABLE plsport_playsport._spent_all convert to character set utf8 collate utf8_general_ci;
ALTER TABLE plsport_playsport._spent_one_month convert to character set utf8 collate utf8_general_ci;
ALTER TABLE plsport_playsport._spent_three_month convert to character set utf8 collate utf8_general_ci;
ALTER TABLE plsport_playsport._last_login_time convert to character set utf8 collate utf8_general_ci;
ALTER TABLE plsport_playsport._user_city2 convert to character set utf8 collate utf8_general_ci;

ALTER TABLE actionlog._action_log2_devices ADD INDEX (`userid`);
ALTER TABLE actionlog._action_log2_day_count ADD INDEX (`userid`);
ALTER TABLE plsport_playsport._spent_all ADD INDEX (`userid`);
ALTER TABLE plsport_playsport._spent_one_month ADD INDEX (`userid`);
ALTER TABLE plsport_playsport._spent_three_month ADD INDEX (`userid`);
ALTER TABLE plsport_playsport._last_login_time ADD INDEX (`userid`);
ALTER TABLE plsport_playsport._user_city2 ADD INDEX (`userid`);


create table plsport_playsport._list_1 engine = myisam
select c.userid, c.nickname, c.day_count, d.total_spent
from (
    SELECT a.userid, b.nickname, a.day_count  
    FROM actionlog._action_log2_day_count a left join plsport_playsport.member b on a.userid = b.userid) as c
    left join plsport_playsport._spent_all as d on c.userid = d.userid;

create table plsport_playsport._list_2 engine = myisam
select c.userid, c.nickname, c.day_count, c.total_spent, d.three_month_spent, c.one_month_spent 
from (
    SELECT a.userid, a.nickname, a.day_count, a.total_spent, b.one_month_spent
    FROM plsport_playsport._list_1 a left join plsport_playsport._spent_one_month b on a.userid = b.userid) as c
    left join plsport_playsport._spent_three_month as d on c.userid = d.userid;

create table plsport_playsport._list_3 engine = myisam
SELECT a.userid, a.nickname, a.day_count, a.total_spent, a.three_month_spent, a.one_month_spent, b.p_pc, b.p_mobile
FROM plsport_playsport._list_2 a left join actionlog._action_log2_devices b on a.userid = b.userid;

create table plsport_playsport._list_4 engine = myisam
SELECT a.userid, a.nickname, a.day_count, a.total_spent, a.three_month_spent, a.one_month_spent, a.p_pc, a.p_mobile, b.last_login
FROM plsport_playsport._list_3 a left join plsport_playsport._last_login_time b on a.userid = b.userid;

# create table plsport_playsport._list_4 engine = myisam
# SELECT a.userid, a.nickname, a.day_count, a.total_spent, a.three_month_spent, a.one_month_spent, a.p_pc, a.p_mobile, b.last_login
# FROM plsport_playsport._list_3 a left join plsport_playsport._last_login_time b on a.userid = b.userid;

create table plsport_playsport._list_5 engine = myisam
SELECT a.userid, a.nickname, a.day_count, a.total_spent, a.three_month_spent, a.one_month_spent, a.p_pc, a.p_mobile, date(a.last_login) as last_login, b.city
FROM plsport_playsport._list_4 a left join plsport_playsport._user_city2 b on a.userid = b.userid;

create table plsport_playsport._list_6 engine = myisam
SELECT * FROM plsport_playsport._list_5
where three_month_spent is not null;

create table plsport_playsport._list_7 engine = myisam
select userid, nickname, day_count, total_spent, three_month_spent, round((cnt-rank+1)/cnt,2) as percentile, one_month_spent, p_pc, p_mobile, last_login, city
from (SELECT userid, nickname, day_count, total_spent, three_month_spent, one_month_spent, p_pc, p_mobile, last_login, city, @curRank := @curRank + 1 AS rank
      FROM plsport_playsport._list_6, (SELECT @curRank := 0) r
      order by three_month_spent desc) as dt,
     (select count(distinct userid) as cnt from plsport_playsport._list_6) as ct;

create table plsport_playsport._list_8 engine = myisam
SELECT * 
FROM plsport_playsport._list_7
where percentile > 0.49;

SELECT 'userid', '暱稱', '網站登入天數','站內總消費額','近三個月站內消費額','級距','近一個月站內消費額','電腦使用比例','手機使用比例','最近上站日','居住地' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_list_8_20150824.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._list_8);



# to Eddy ：Tue, May 12, 2015 at 6:01 PM
# 請提供近三個月的ARPU，謝謝！
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4688&projectId=11
# 近三個月站內消費額
create table plsport_playsport._spent_three_month engine = myisam
SELECT userid, sum(amount) as three_month_spent
FROM plsport_playsport.pcash_log
where payed = 1 and type = 1
and date(date) between '2015-02-07' and '2015-05-07'
group by userid;

        create table plsport_playsport._spent_2 engine = myisam
        select count(a.userid) as user_count, sum(a.total_spent) as total_spent
        from (
            SELECT userid, sum(amount) as total_spent
            FROM plsport_playsport.pcash_log
            where payed = 1 and type = 1
            and date(date) between '2015-02-07' and '2015-03-07'
            group by userid) as a;
        insert ignore into plsport_playsport._spent_2
        select count(a.userid) as user_count, sum(a.total_spent) as total_spent
        from (
            SELECT userid, sum(amount) as total_spent
            FROM plsport_playsport.pcash_log
            where payed = 1 and type = 1
            and date(date) between '2015-03-08' and '2015-04-07'
            group by userid) as a;
        insert ignore into plsport_playsport._spent_2
        select count(a.userid) as user_count, sum(a.total_spent) as total_spent
        from (
            SELECT userid, sum(amount) as total_spent
            FROM plsport_playsport.pcash_log
            where payed = 1 and type = 1
            and date(date) between '2015-04-08' and '2015-05-07'
            group by userid) as a;



# =================================================================================================
# 任務: [201410-B-3] 棒球即時比分賽事數據 - MVP測試名單 [新建] 2015-05-06 (阿達)
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4691&projectId=11
# 提供此任務優化MVP測試名單
# 
# 內容
# 1. MVP測試名單
# 條件：
# a. 今年MLB即時比分PV前50%
# b. 此問卷第二題回答需要及非常需要
# 欄位：
# a. 帳號
# b. 暱稱
# c. 今年MLB即時比分pv及全站佔比
# d. 手機、電腦使用比例
# =================================================================================================

CREATE TABLE actionlog._livescore engine = myisam SELECT userid, uri, time, platform_type FROM actionlog.action_201501 WHERE uri LIKE '%/livescore%' and userid <> '';
INSERT IGNORE INTO actionlog._livescore SELECT userid, uri, time, platform_type FROM actionlog.action_201502 WHERE uri LIKE '%/livescore%' and userid <> '';
INSERT IGNORE INTO actionlog._livescore SELECT userid, uri, time, platform_type FROM actionlog.action_201503 WHERE uri LIKE '%/livescore%' and userid <> '';
INSERT IGNORE INTO actionlog._livescore SELECT userid, uri, time, platform_type FROM actionlog.action_201504 WHERE uri LIKE '%/livescore%' and userid <> '';
INSERT IGNORE INTO actionlog._livescore SELECT userid, uri, time, platform_type FROM actionlog.action_201505 WHERE uri LIKE '%/livescore%' and userid <> '';

update actionlog._livescore set platform_type=2 where platform_type=3;

# 處理造訪即時比分頁預設的聯盟(NBA OR MLB)
CREATE TABLE actionlog._livescore_1_1 engine = myisam
SELECT a.userid, a.uri, a.time, platform_type, (case when (locate('&',a.t)=0) then a.t else substr(a.t,1,locate('&',a.t)-1) end) as p
FROM (
    SELECT userid, uri, time, platform_type, (case when (locate('aid=',uri)=0) then 3 else substr(uri, locate('aid=',uri)+4, length(uri)) end) as t
    FROM actionlog._livescore
    where time between '2014-12-01 00:00:00' and '2015-04-31 23:59:59') as a; # 4/1之前, 如果造訪livescore.php, 預設聯盟是NBA

CREATE TABLE actionlog._livescore_1_2 engine = myisam
SELECT a.userid, a.uri, a.time, platform_type, (case when (locate('&',a.t)=0) then a.t else substr(a.t,1,locate('&',a.t)-1) end) as p
FROM (
    SELECT userid, uri, time, platform_type, (case when (locate('aid=',uri)=0) then 1 else substr(uri, locate('aid=',uri)+4, length(uri)) end) as t
    FROM actionlog._livescore
    where time between '2015-04-01 00:00:00' and now()) as a; 

create table actionlog._livescore_with_allianceid engine = myisam
SELECT * FROM actionlog._livescore_1_1;
insert ignore into actionlog._livescore_with_allianceid
SELECT * FROM actionlog._livescore_1_2;

create table actionlog._livescore_with_mlb engine = myisam
SELECT * FROM actionlog._livescore_with_allianceid
where p=1;

create table actionlog._livescore_with_mlb_pv engine = myisam
SELECT userid, count(uri) as pv 
FROM actionlog._livescore_with_mlb
group by userid;

create table actionlog._livescore_with_mlb_pv_p engine = myisam
select userid, pv, round((cnt-rank+1)/cnt,2) as pv_percentile
from (SELECT userid, pv, @curRank := @curRank + 1 AS rank
      FROM actionlog._livescore_with_mlb_pv, (SELECT @curRank := 0) r
      order by pv desc) as dt,
     (select count(distinct userid) as cnt from actionlog._livescore_with_mlb_pv) as ct;

create table actionlog._livescore_with_device engine = myisam
select a.userid, sum(a.pc) as pc, sum(a.mobile) as mobile
from (
    SELECT userid, (case when (platform_type=1) then 1 else 0 end) as pc, (case when (platform_type=2) then 1 else 0 end) as mobile
    FROM actionlog._livescore_with_mlb) as a
group by a.userid;

create table actionlog._livescore_with_device1 engine = myisam
SELECT userid, round((pc/(pc+mobile)),3) as pc_p, round((mobile/(pc+mobile)),3) as mobile_p
FROM actionlog._livescore_with_device;

# 最近一次的登入時間
CREATE TABLE plsport_playsport._last_login_time engine = myisam
SELECT userid, max(signin_time) as last_login
FROM plsport_playsport.member_signin_log_archive
GROUP BY userid;

ALTER TABLE actionlog._livescore_with_mlb_pv_p convert to character set utf8 collate utf8_general_ci;
ALTER TABLE actionlog._livescore_with_device1 convert to character set utf8 collate utf8_general_ci;
ALTER TABLE plsport_playsport._last_login_time convert to character set utf8 collate utf8_general_ci;
ALTER TABLE actionlog._livescore_with_mlb_pv_p ADD INDEX (`userid`);
ALTER TABLE actionlog._livescore_with_device1 ADD INDEX (`userid`);
ALTER TABLE plsport_playsport._last_login_time ADD INDEX (`userid`);

create table plsport_playsport._livescore_list1 engine = myisam
SELECT a.userid, b.nickname, a.pv, a.pv_percentile 
FROM actionlog._livescore_with_mlb_pv_p a left join plsport_playsport.member b on a.userid = b.userid;

create table plsport_playsport._livescore_list2 engine = myisam
SELECT a.userid, a.nickname, a.pv, a.pv_percentile, b.pc_p, b.mobile_p
FROM plsport_playsport._livescore_list1 a left join actionlog._livescore_with_device1 b on a.userid = b.userid;

create table plsport_playsport._livescore_list3 engine = myisam
SELECT a.userid, a.nickname, a.pv, a.pv_percentile, a.pc_p, a.mobile_p, date(b.last_login) as d
FROM plsport_playsport._livescore_list2 a left join plsport_playsport._last_login_time b on a.userid = b.userid;


        create table plsport_playsport._qu engine = myisam
        SELECT userid, `1429069219` as q
        FROM plsport_playsport.questionnaire_201504151141419829_answer;


create table plsport_playsport._livescore_list4 engine = myisam
SELECT a.userid, a.nickname, a.pv, a.pv_percentile, a.pc_p, a.mobile_p, a.d, b.q
FROM plsport_playsport._livescore_list3 a left join plsport_playsport._qu b on a.userid = b.userid
order by a.pv desc;

create table plsport_playsport._livescore_list5 engine = myisam
SELECT * FROM plsport_playsport._livescore_list4
where pv_percentile > 0.49 and q in (4,5);

ALTER TABLE plsport_playsport._livescore_list5 CHANGE `q` `q` VARCHAR(10) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL;

update plsport_playsport._livescore_list5 set q='需要' where q=4;
update plsport_playsport._livescore_list5 set q='非常需要' where q=5;

SELECT '帳號', '暱稱', 'MLB即時比分pv', '級距%','電腦使用比例','手機使用比例','最後登入','問券第二題' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_livescore_list5.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._livescore_list5);


# =================================================================================================
# 任務: [研究]討論區的紅人在銷售上是否更好 [新建]
#     添加備註 	    編輯詳情 	
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4179&projectId=11
#     • 更多動作
# 
# 說明: 在討論區中活躍度高的人, 在賣牌的銷售上是否更好
# 負責人: eddy
# 研究內容:
# 
# 1. 討論區活躍度(紅人)定義
# 2. 使用者個人的討論區活躍度和賣牌銷售是否有正相關?
# 3. 有在寫分析文的人和沒在寫的人其賣牌銷售是否有差異?
# 4. 在討論區活躍度高的人也代表個人頁造訪率也高, 紅人們的個人頁>購牌轉換率有什麼差別?
#    (例如:有的殺手不需靠在討論區互動也能賣的很好, 有的紅人則是靠大量在站上曝光才熱賣, 他們差在那?)
# =================================================================================================

create table plsport_playsport._forum engine = myisam
SELECT a.subjectid, (case when (a.includeprediction=1) then 1 else 0 end) as predict, a.allianceid, b.alliancename, a.gametype, (case when (gametype=1) then 1 else 0 end) as isanalysis,
       a.subject, a.viewtimes, a.postuser, a.posttime, date(a.posttime) as d, a.replycount, a.pushcount
FROM plsport_playsport.forum a left join plsport_playsport.alliance b on a.allianceid = b.allianceid
where date(posttime) between '2014-01-01' and subdate(now(),1) #取到今天的前一天就好
and a.allianceid  <> 999;

# 如果有跨日, 取正負4小時來判斷是否為同一天
# 例, 如果一個人在5號02:00發文, 那會取正負4小時, 即前一天4號22:00~隔天5號06:00來判斷
# 會判斷該使用者4號或5號有沒有賣牌, 如果有賣牌, 即判定賣牌和貼文有連結

create table plsport_playsport._forum1 engine = myisam
SELECT subjectid, predict, allianceid, alliancename, gametype, isanalysis, subject, viewtimes, postuser, posttime, 
       date(addtime(posttime, '04:00:00')) as range1, date(subtime(posttime, '04:00:00')) as range2, replycount, pushcount #正負4小時
FROM plsport_playsport._forum;

        create table plsport_playsport._forum1_1 engine = myisam
        SELECT * FROM plsport_playsport._forum1
        where range1 = range2;#沒跨日的

        create table plsport_playsport._forum1_2 engine = myisam
        SELECT * FROM plsport_playsport._forum1
        where range1 <> range2;#有跨日的

        create table plsport_playsport._forum1_2_a engine = myisam
        SELECT subjectid, predict, allianceid, alliancename, gametype, isanalysis, subject, viewtimes, postuser, posttime, range1 as d, replycount, pushcount 
        FROM plsport_playsport._forum1_2;
        insert ignore into plsport_playsport._forum1_2_a
        SELECT subjectid, predict, allianceid, alliancename, gametype, isanalysis, subject, viewtimes, postuser, posttime, range2 as d, replycount, pushcount 
        FROM plsport_playsport._forum1_2;
        insert ignore into plsport_playsport._forum1_2_a
        SELECT subjectid, predict, allianceid, alliancename, gametype, isanalysis, subject, viewtimes, postuser, posttime, range1 as d, replycount, pushcount  
        FROM plsport_playsport._forum1_1;

# 每個上架的預測, 總共收益多少金額
create table plsport_playsport._revenue_detail engine = myisam
SELECT id_bought, sum(buy_price) as revenue
FROM plsport_playsport.predict_buyer
group by id_bought;

        ALTER TABLE plsport_playsport.predict_seller ADD INDEX (`id`);
        ALTER TABLE plsport_playsport._revenue_detail ADD INDEX (`id_bought`);

# (a)每個上架的預測(主名單) left join 總共收益多少金額
create table plsport_playsport._seller_detail engine = myisam
SELECT a.id, a.sellerid, a.mode, a.sale_allianceid, a.sale_date, date(a.sale_date) as d, a.promotion, a.analysis_flag, a.buyer_count, a.sale_price, b.revenue
FROM plsport_playsport.predict_seller a left join plsport_playsport._revenue_detail b on a.id = b.id_bought
where date(sale_date) between '2014-01-01' and subdate(now(),1);

        ALTER TABLE plsport_playsport._seller_detail ADD INDEX (`sale_allianceid`, `d`, `sellerid`);
        ALTER TABLE plsport_playsport._forum1_2_a ADD INDEX (`allianceid`, `d`, `postuser`);

# 把(a)和 plsport_playsport._forum1_2_a 做left join
create table plsport_playsport._seller_detail_1 engine = myisam
SELECT a.id, a.sellerid, a.mode, a.sale_allianceid, a.sale_date, a.promotion, a.analysis_flag, a.buyer_count, a.sale_price, a.revenue, 
       b.gametype as post_type, b.subject, b.predict, b.posttime, b.viewtimes, b.replycount, b.pushcount, 
       ifnull((abs(time_to_sec(timediff(a.sale_date,b.posttime)))), 0) as timegap
FROM plsport_playsport._seller_detail a left join plsport_playsport._forum1_2_a b 
on a.sale_allianceid =  b.allianceid and a.d = b.d and a.sellerid = b.postuser;

        # 如果id 產生duplicate, 那只取最小的timegap
        create table plsport_playsport._get_lowerest_timegap engine = myisam
        select f.id, ifnull(f.timegap, 0) as timegap
        from (
            SELECT id, min(timegap) as timegap
            FROM plsport_playsport._seller_detail_1
            group by id) as f;

        ALTER TABLE plsport_playsport._seller_detail_1 ADD INDEX (`id`,`timegap`);
        ALTER TABLE plsport_playsport._get_lowerest_timegap ADD INDEX (`id`,`timegap`);

# 如果id 產生duplicate, 那只取最小的timegap
create table plsport_playsport._seller_detail_2 engine = myisam
select a. id, a.sellerid, a.mode, a.sale_allianceid, a.sale_date, a.promotion, a.analysis_flag, a.buyer_count, a.sale_price, a.revenue, 
       a.post_type, a.subject, a.predict, a.posttime, a.viewtimes, a.replycount, a.pushcount, a.timegap
from plsport_playsport._seller_detail_1 as a inner join plsport_playsport._get_lowerest_timegap as b on a.id = b.id and a.timegap = b.timegap;

create table plsport_playsport._seller_detail_3 engine = myisam
SELECT a.id, a.sellerid, a.mode, a.sale_allianceid, b.alliancename, a.sale_date, date(a.sale_date) as d, a.promotion, a.analysis_flag, a.buyer_count, a.sale_price, a.revenue, (case when (a.post_type is not null) then 1 else 0 end) as ispost,
       a.post_type, a.predict as inc_predict, a.posttime, a.viewtimes, a.replycount, a.pushcount, abs((time_to_sec(timediff(a.sale_date,posttime)))/3600) as timegap
FROM plsport_playsport._seller_detail_2 a left join plsport_playsport.alliance b on a.sale_allianceid = b.allianceid;

        update plsport_playsport._seller_detail_3 set ispost=0 where timegap >= 8;
        ALTER TABLE `_seller_detail_3` CHANGE `mode` `mode` VARCHAR(4) NOT NULL COMMENT '賣的盤別,1北富銀,2國際盤';
        update plsport_playsport._seller_detail_3 set mode='運彩' where mode = 1;
        update plsport_playsport._seller_detail_3 set mode='國際' where mode = 2;

# 補上近10日在討論區上的人氣
create table plsport_playsport._forum2_with_10_days engine = myisam 
select a.d, a.allianceid, a.postuser, sum(a.viewtimes) as viewtimes, sum(a.replycount) as replycount, sum(pushcount) as pushcount
from (
    SELECT date(posttime) as d, allianceid, postuser, viewtimes, replycount, pushcount
    FROM plsport_playsport._forum1) as a
group by a.d, a.allianceid, a.postuser;

        # 這段是要給python跑的
        # C:\proc\python\calculate\calculate_10_days_forum_population.py

        # 在這裡執行calculate_10_days_forum_population.py
        # SELECT (case when (postuser is not null) then '2015-05-11' end) as d ,allianceid, postuser, 
        #        sum(viewtimes) as viewtime10, sum(replycount) as replycount10, sum(pushcount) as pushcount10 
        # FROM plsport_playsport._forum2_with_10_days
        # where d between subdate(now(),10) and '2015-05-1'
        # group by allianceid, postuser;

        # 執行完上面的.py會產生plsport_playsport._forum2_with_10_days_python

        ALTER TABLE plsport_playsport._seller_detail_3 ADD INDEX (`d`,`sale_allianceid`,`sellerid`);
        ALTER TABLE plsport_playsport._forum2_with_10_days_python ADD INDEX (`d`,`allianceid`,`postuser`);
        ALTER TABLE plsport_playsport._seller_detail_3 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE plsport_playsport._forum2_with_10_days_python convert to character set utf8 collate utf8_general_ci;
        
        ALTER TABLE `_forum2_with_10_days_python` CHANGE `postuser` `postuser` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE `_forum2_with_10_days_python` CHANGE `d` `d` DATE NULL DEFAULT NULL;
        
create table plsport_playsport._seller_detail_4 engine = myisam
SELECT a.id, a.sellerid, a.mode, a.sale_allianceid, a.alliancename, a.sale_date, (case when (a.promotion<>'') then 1 else 0 end) as promotion, a.analysis_flag, a.buyer_count, a.sale_price, a.revenue, a.ispost,
       a.post_type, a.inc_predict, a.posttime, a.viewtimes, a.replycount, a.pushcount, a.timegap, b.viewtime10, b.replycount10, b.pushcount10
FROM plsport_playsport._seller_detail_3 a left join plsport_playsport._forum2_with_10_days_python b 
on a.sale_allianceid = b.allianceid and a.d = b.d and a.sellerid = b.postuser;      
        
# 以每個上架的預測來看的資料
select 'id','sellerid','mode','sale_allianceid','alliancename','sale_date','promotion','analysis_flag','buyer_count','sale_price','revenue',
       'ispost','post_type','inc_predict','posttime','viewtimes','replycount','pushcount','timegap','viewtimes10','replycount10','pushcount10' union (
SELECT * 
into outfile 'C:/Users/1-7_ASUS/Desktop/_seller_detail_4.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._seller_detail_4);


# 以每個殺手的角度來看的資料
create table plsport_playsport._seller_detail_5_by_user engine = myisam
SELECT sellerid, sum(buyer_count) as total_buy_count ,sum(revenue) as total_earn, sum(promotion) as promotion, sum(analysis_flag) as analysis_flag ,sum(ispost) as post_count, sum(inc_predict) as inc_predict, 
       sum(viewtimes) as viewtimes, sum(replycount) as replycount, sum(pushcount) as pushcount 
FROM plsport_playsport._seller_detail_4
group by sellerid;

# 分析文數量計算
create table plsport_playsport._analysis_post_count engine = myisam
SELECT sellerid, sum(post_type) as analysis_post_count
FROM plsport_playsport._seller_detail_4
where post_type = 1
group by sellerid;

# 分析文數量計算(歷史的)
create table plsport_playsport._analysis_post_count_1 engine = myisam
SELECT postuser, count(subjectid) as analysis_post_new
FROM plsport_playsport._forum
where gametype = 1
and date(posttime) between '2014-01-01' and subdate(now(),1)
group by postuser;

# 新增:最讚分析文數量
create table plsport_playsport._analysis_post_count_best engine = myisam
SELECT userid, count(subjectid) as best_post 
FROM plsport_playsport.analysis_king
where date(got_time) between '2014-01-01' and subdate(now(),1)
group by userid;


create table plsport_playsport._seller_detail_6 engine = myisam
SELECT a.sellerid, a.total_buy_count, a.total_earn, a.promotion, a.analysis_flag , a.post_count, b.analysis_post_count, a.inc_predict, a.viewtimes, a.replycount, a.pushcount 
FROM plsport_playsport._seller_detail_5_by_user a left join plsport_playsport._analysis_post_count b on a.sellerid = b.sellerid;

create table plsport_playsport._seller_detail_7 engine = myisam
SELECT a.sellerid, a.total_buy_count, a.total_earn, a.promotion, a.analysis_flag , a.post_count, a.analysis_post_count, b.best_post, a.inc_predict, a.viewtimes, a.replycount, a.pushcount 
FROM plsport_playsport._seller_detail_6 a left join plsport_playsport._analysis_post_count_best b on a.sellerid = b.userid;

create table plsport_playsport._seller_detail_8 engine = myisam
SELECT a.sellerid, a.total_buy_count, a.total_earn, a.promotion, a.analysis_flag , a.post_count, a.analysis_post_count, b.analysis_post_new, a.best_post, a.inc_predict, a.viewtimes, a.replycount, a.pushcount 
FROM plsport_playsport._seller_detail_7 a left join plsport_playsport._analysis_post_count_1 b on a.sellerid = b.postuser;


select 'sellerid','total_buy_count','total_earn','promotion','analysis_flag','post_count','analysis_post_count','analysis_post_new','best_post', 'inc_predict','viewtimes','replycount','pushcount' union (
SELECT * 
into outfile 'C:/Users/1-7_ASUS/Desktop/_seller_detail_6.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._seller_detail_8);


# 有沒有寫過分析文
select a.isanalysis, count(sellerid) ,sum(a.total_earn)
from (
    SELECT sellerid, total_earn, (case when (analysis_post_count is not null) then 1 else 0 end) as isanalysis
    FROM plsport_playsport._seller_detail_6) as a
group by a.isanalysis;

# 有沒有標示殺手小叮嚀
select a.isflag, count(sellerid) ,sum(a.total_earn)
from (
    SELECT sellerid, total_earn, (case when (analysis_flag is not null) then 1 else 0 end) as isflag
    FROM plsport_playsport._seller_detail_6) as a
group by a.isanalysis;



# =================================================================================================
# 小魔女 2015-05-29 (userid: a7361416)
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4740&projectId=11
# To Eddy：
# 請於 6/2(二)下午二點於屏東縣屏東市廣東路171號，協助訪談重度消費者~小魔女~
# 1. 請先研究使用者使用行為
# 2. 訪談完請上傳錄音檔，並於兩週後交訪談報告，檔名範例 中度消費者_小球
# hugr86  重度買牌客(台中鳥日高鐵)
# =================================================================================================

# =================================================================================================
# 行銷企劃 - [201505-A-2] 消費者訪談 - 訪談 [進行中] (阿達) 2015-07-02
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4740&projectId=11
# 任務頁面 | 專案信息
# To Eddy：
# 
# 請於 7/3(五)下午二點半於台中高鐵站協助訪談極重度消費者hugr
#  
# 1. 請先研究使用者使用行為
# 2. 訪談完請上傳錄音檔，並於兩週後交訪談報告，檔名範例 中度消費者_小球
# =================================================================================================

create table actionlog._user_FB1404275823 engine = myisam SELECT userid, uri, time, user_agent, platform_type FROM actionlog.action_201501 where userid = 'FB1404275823';
insert ignore into actionlog._user_FB1404275823 SELECT userid, uri, time, user_agent, platform_type FROM actionlog.action_201502 where userid = 'FB1404275823';
insert ignore into actionlog._user_FB1404275823 SELECT userid, uri, time, user_agent, platform_type FROM actionlog.action_201503 where userid = 'FB1404275823';
insert ignore into actionlog._user_FB1404275823 SELECT userid, uri, time, user_agent, platform_type FROM actionlog.action_201504 where userid = 'FB1404275823';
insert ignore into actionlog._user_FB1404275823 SELECT userid, uri, time, user_agent, platform_type FROM actionlog.action_201505 where userid = 'FB1404275823';
insert ignore into actionlog._user_FB1404275823 SELECT userid, uri, time, user_agent, platform_type FROM actionlog.action_201506 where userid = 'FB1404275823';
insert ignore into actionlog._user_FB1404275823 SELECT userid, uri, time, user_agent, platform_type FROM actionlog.action_201507 where userid = 'FB1404275823';
insert ignore into actionlog._user_FB1404275823 SELECT userid, uri, time, user_agent, platform_type FROM actionlog.action_201508 where userid = 'FB1404275823';

SELECT user_agent, count(uri)
FROM actionlog._user_FB1404275823
group by user_agent;

SELECT platform_type, count(uri)
FROM actionlog._user_FB1404275823
group by platform_type;

# 1	28165
# 2	10789
# 3	3289

create table actionlog._user_FB1404275823_1 engine = myisam
SELECT userid, uri, time, platform_type, date(time) as d, substr(time,12,2) as h
FROM actionlog._user_FB1404275823
order by time desc;

SELECT d, count(uri) as c 
FROM actionlog._user_FB1404275823_1
group by d;

SELECT platform_type, h, count(uri) as c
FROM actionlog._user_FB1404275823_1
group by platform_type, h
order by h ;

create table actionlog._user_FB1404275823_1_payway engine = myisam
SELECT userid, name, createon, price, payway, platform_type, substr(createon,1,7) as m
FROM plsport_playsport.order_data
where userid = 'FB1404275823'
and sellconfirm = 1;

create table actionlog._user_FB1404275823_1_action engine = myisam
select b.userid, b.uri, b.time, b.platform_type, b.page, (case when (locate('&',b.act)>0) then substr(b.act,1,locate('&',b.act)-1) else '' end) as act
from (
    select a.userid, a.uri, a.time, a.platform_type, a.page, (case when (locate('action=', uri)>0) then substr(uri, locate('action=', uri)+7,length(uri)) else '' end) as act
    from (
        SELECT userid, uri, time, platform_type, substr(uri,2,locate('.php',uri)-2) as page
        FROM actionlog._user_FB1404275823_1) as a) as b;


create table actionlog._user_FB1404275823_1_action_1 engine = myisam
select b.userid, b.uri, b.time, b.platform_type, (case when (b.page='') then 'index' else b.page end) as page, b.act, b.dur
from (
    select a.userid, a.uri, a.time, a.platform_type, a.page, a.act, (case when (locate('&',a.dur)>0) then substr(a.dur,1,(locate('&',a.dur)-1)) else '' end) as dur
    from (
        SELECT userid, uri, time, platform_type, page, act, (case when (locate('during=',uri))>0 then substr(uri,(locate('during=',uri)+7), length(uri)) else '' end) as dur
        FROM actionlog._user_FB1404275823_1_action) as a) as b;

select *
from (
    SELECT page, act, dur, count(uri) as c
    FROM actionlog._user_FB1404275823_1_action_1
    group by page, act, dur) as a
order by a.c desc;

select a.ym, sum(a.amount) as amount
from (
    SELECT userid, amount, substr(date,1,7) as ym
    FROM plsport_playsport.pcash_log
    where payed = 1 and type = 1 and userid ='FB1404275823') as a
group by a.ym;

select a.p, sum(a.buy_price) as price, a.ym
from (
    SELECT substr(position,1,3) as p, buy_price, substr(buy_date,1,7) as ym
    FROM plsport_playsport._predict_buyer_with_cons
    where buyerid = 'FB1404275823') as a
group by a.p, a.ym;


# =================================================================================================
# 任務: [201504-D-2] 網站放置廣告 - 統計 [新建] (阿達) 2015-06-01
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4652&projectId=11
# 統計放置站外廣告是否影響使用者行為
# 
# 6/4 A/B testing報告 
#    內容
#    1. A/B testing名單 (30%)
#    2. 統計A/B testing結果
# 統計看文章篇數、文章內頁pv、站內購買業績是否有差異
# 2015-06-01 17:12
#    決議A/B testing再做一個月，請於 7/3完成報告
#    請再多檢驗推數、回覆數是否有影響
# =================================================================================================

create table actionlog._forum engine = myisam
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201504
where userid <> '' and time between '2015-04-29 00:00:00' and now()
and uri like '%/forum%';
insert ignore into actionlog._forum
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201505
where userid <> '' and time between '2015-04-29 00:00:00' and now()
and uri like '%/forum%';
insert ignore into actionlog._forum
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201506
where userid <> '' and time between '2015-04-29 00:00:00' and now()
and uri like '%/forum%';
insert ignore into actionlog._forum
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201507
where userid <> '' and time between '2015-04-29 00:00:00' and now()
and uri like '%/forum%';

create table actionlog._forum_1 engine = myisam
SELECT userid, uri, time, platform_type, (case when (locate('subjectid',uri)>0) then substr(uri,locate('subjectid',uri)+10,length(uri)) else '' end) as sid 
FROM actionlog._forum;

create table actionlog._forum_2 engine = myisam
SELECT userid, uri, time, platform_type, (case when (locate('&',sid)>0) then substr(sid,1,locate('&',sid)-1) else '' end) as sid
FROM actionlog._forum_1
where time between '2015-06-01 00:00:00' and now();

        ALTER TABLE actionlog._forum_2 CHANGE `sid` `sid` VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL; # 115 secs
        ALTER TABLE actionlog._forum_2 convert to character set utf8 collate utf8_general_ci; # 119 secs
        
        create table actionlog._temp1 engine = myisam SELECT * FROM actionlog._forum_2 limit 0, 7000000;
        create table actionlog._temp2 engine = myisam SELECT * FROM actionlog._forum_2 limit 7000000, 7000000;
        create table actionlog._temp3 engine = myisam SELECT * FROM actionlog._forum_2 limit 14000000, 7000000;
        
#         create table actionlog._temp4 engine = myisam SELECT * FROM actionlog._forum_2 limit 24000000, 8000000;
#         create table actionlog._temp5 engine = myisam SELECT * FROM actionlog._forum_2 limit 32000000, 8000000;
       
        create table actionlog._temp1_group engine = myisam SELECT userid, sid, platform_type FROM actionlog._temp1 group by userid, sid, platform_type;
        create table actionlog._temp2_group engine = myisam SELECT userid, sid, platform_type FROM actionlog._temp2 group by userid, sid, platform_type;     
        create table actionlog._temp3_group engine = myisam SELECT userid, sid, platform_type FROM actionlog._temp3 group by userid, sid, platform_type;
        
#         create table actionlog._temp4_group engine = myisam SELECT userid, sid, platform_type FROM actionlog._temp4 group by userid, sid, platform_type;   
#         create table actionlog._temp5_group engine = myisam SELECT userid, sid, platform_type FROM actionlog._temp5 group by userid, sid, platform_type;    
        
        create table actionlog._temp0_group engine = myisam select * from actionlog._temp1_group;
        insert ignore into actionlog._temp0_group select * from actionlog._temp2_group;
        insert ignore into actionlog._temp0_group select * from actionlog._temp3_group;
        
#         insert ignore into actionlog._temp0_group select * from actionlog._temp4_group;
#         insert ignore into actionlog._temp0_group select * from actionlog._temp5_group;
        
        # ALTER TABLE actionlog._forum_2 ADD INDEX (`userid`);
        # ALTER TABLE actionlog._forum_2 ADD INDEX (`sid`,`platform_type`);
        # ALTER TABLE actionlog._forum_2 ADD INDEX (`platform_type`);
        # it takes arount 1276 secs

create table actionlog._forum_3 engine = myisam SELECT userid, sid, platform_type FROM actionlog._temp0_group group by userid, sid, platform_type; 

# 有分裝置類型
create table actionlog._forum_4 engine = myisam
SELECT userid, platform_type, count(sid) as read_count 
FROM actionlog._forum_3
where sid <> ''
group by userid, platform_type;

# 沒有分裝置類型
create table actionlog._forum_4_1 engine = myisam
SELECT userid, count(sid) as read_count 
FROM actionlog._forum_3
where sid <> ''
group by userid;


create table actionlog._forum_4_with_read_count_by_devices engine = myisam
SELECT (case when (((b.id%20)+1)<7) then 'a' else 'b' end) as abtest, a.userid, a.platform_type, a.read_count
FROM actionlog._forum_4 a left join plsport_playsport.member b on a.userid = b.userid;

create table actionlog._forum_4_with_read_count_all_devices engine = myisam
SELECT (case when (((b.id%20)+1)<7) then 'a' else 'b' end) as abtest, a.userid, a.read_count
FROM actionlog._forum_4_1 a left join plsport_playsport.member b on a.userid = b.userid;


create table actionlog._forum_4_with_forum_pv_by_devices engine = myisam
SELECT userid, platform_type, count(uri) as forum_pv 
FROM actionlog._forum_2
where uri like '%forumdetail.php%'
group by userid, platform_type;

create table actionlog._forum_4_with_forum_pv_all_devices engine = myisam
SELECT userid, count(uri) as forum_pv 
FROM actionlog._forum_2
where uri like '%forumdetail.php%'
group by userid;

create table actionlog._forum_4_with_forum_pv_by_devices_1 engine = myisam
SELECT (case when (((b.id%20)+1)<7) then 'a' else 'b' end) as abtest, a.userid, a.platform_type, a.forum_pv 
FROM actionlog._forum_4_with_forum_pv_by_devices a left join plsport_playsport.member b on a.userid = b.userid;

create table actionlog._forum_4_with_forum_pv_all_devices_1 engine = myisam
SELECT (case when (((b.id%20)+1)<7) then 'a' else 'b' end) as abtest, a.userid, a.forum_pv 
FROM actionlog._forum_4_with_forum_pv_all_devices a left join plsport_playsport.member b on a.userid = b.userid;


SELECT 'abtest', 'userid', 'platform', 'read_count' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_forum_4_with_read_count_by_devices.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._forum_4_with_read_count_by_devices);

SELECT 'abtest', 'userid',  'read_count' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_forum_4_with_read_count_all_devices.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._forum_4_with_read_count_all_devices);

SELECT 'abtest', 'userid', 'platform', 'forum_pv' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_forum_4_with_forum_pv_by_devices.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._forum_4_with_forum_pv_by_devices_1);

SELECT 'abtest', 'userid', 'forum_pv' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_forum_4_with_forum_pv_all_devices.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._forum_4_with_forum_pv_all_devices_1);


create table plsport_playsport._pcash_log engine = myisam 
SELECT userid, sum(amount) as spent 
FROM plsport_playsport.pcash_log
where payed = 1 and type = 1
and date between '2015-06-01 00:00:00' and now()
group by userid;

create table actionlog._forum_4_with_read_count_all_devices_and_spent engine = myisam
SELECT a.abtest, a.userid, a.read_count, b.spent
FROM actionlog._forum_4_with_read_count_all_devices a left join plsport_playsport._pcash_log b on a.userid = b.userid;


# 請再多檢驗推數、回覆數是否有影響


create table plsport_playsport._forumcontent engine = myisam
select a.userid, count(a.content) as reply_count
from (
    SELECT userid, content 
    FROM plsport_playsport.forumcontent
    where date(postdate) between '2015-04-29' and '2015-06-30') as a
group by a.userid;

create table plsport_playsport._forumcontent_reply_count engine = myisam
SELECT (case when (((b.id%20)+1)<7) then 'a' else 'b' end) as abtest, a.userid, a.reply_count
FROM plsport_playsport._forumcontent a left join plsport_playsport.member b on a.userid = b.userid;

SELECT 'abtest', 'userid', 'rely_count' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_forumcontent_reply_count.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._forumcontent_reply_count);


create table plsport_playsport._like engine = myisam
SELECT userid, count(subject_id) as like_count
FROM plsport_playsport.forum_like
where date(create_date) between '2015-04-29' and '2015-06-30'
group by userid;

create table plsport_playsport._like_count engine = myisam
SELECT (case when (((b.id%20)+1)<7) then 'a' else 'b' end) as abtest, a.userid, a.like_count
FROM plsport_playsport._like a left join plsport_playsport.member b on a.userid = b.userid;

SELECT 'abtest', 'userid', 'like_count' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_like_count.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._like_count);





# =================================================================================================
# 任務: [201412-G-8]文章列表改版-問卷分析 [新建]
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4834&projectId=11
# 說明
# 目的:了解兩個時間區段的問卷結果
#  
# 內容
# - 區分兩個時間的問卷結果
# - 第二次問卷上線時間為5/28 12:00~5/31 12:00
# - 問卷統計：http://www.playsport.cc/questionnaire.php?question=201505121108521342&action=statistics
# =================================================================================================

create table plsport_playsport._qu engine = myisam
SELECT * FROM plsport_playsport.questionnaire_201505121108521342_answer
where spend_minute>0.3
order by spend_minute;

create table plsport_playsport._qu_1 engine = myisam
SELECT userid, write_time, q1, q2, q3 
FROM plsport_playsport._qu;

create table plsport_playsport._qu_2 engine = myisam
SELECT userid, write_time as d, q1, q2, (case when (locate('1',q3)>0) then 1 else 0 end) as f1,
                                        (case when (locate('2',q3)>0) then 1 else 0 end) as f2,
                                        (case when (locate('3',q3)>0) then 1 else 0 end) as f3,
                                        (case when (locate('4',q3)>0) then 1 else 0 end) as f4,
                                        (case when (locate('5',q3)>0) then 1 else 0 end) as f5,
                                        (case when (locate('6',q3)>0) then 1 else 0 end) as f6
FROM plsport_playsport._qu_1;

create table plsport_playsport._qu_2_1 engine = myisam
SELECT * FROM plsport_playsport._qu_2
where d between '2015-05-01 12:00:00' and '2015-05-28 12:00:00';

create table plsport_playsport._qu_2_2 engine = myisam
SELECT * FROM plsport_playsport._qu_2
where d between '2015-05-28 12:00:00' and '2015-05-31 12:00:00';

SELECT q1, count(userid) as c 
FROM plsport_playsport._qu_2_1
group by q1;

SELECT q2, count(userid) as c 
FROM plsport_playsport._qu_2_1
group by q2;

SELECT sum(f1),sum(f2),sum(f3),sum(f4),sum(f5),sum(f6) 
FROM plsport_playsport._qu_2_1;

SELECT q1, count(userid) as c 
FROM plsport_playsport._qu_2_2
group by q1;

SELECT q2, count(userid) as c 
FROM plsport_playsport._qu_2_2
group by q2;

SELECT sum(f1),sum(f2),sum(f3),sum(f4),sum(f5),sum(f6) 
FROM plsport_playsport._qu_2_2;



# =================================================================================================
# 任務: [201504-C-4]即時比分頁新增宣傳單元-ABtesting報告 [新建] (靜怡) 2015-06-12
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4839&projectId=11
# 說明
# 
# 目的：了解宣傳單元是否影響使用者行為
# 
# 內容
# - 測試時間：6/11~7/2
# - 設定測試組別
# - 觀察指標
# 
#     每100人次的點擊率大於即時比分benner廣告的點擊率 
#     即時比PV不受影響
#     廣告位置點擊狀況
#     購買預測金額
# - 報告時間：7/7
# =================================================================================================

# ABtesting已於6/11 10:30上線

# 檢查banner點擊的部分
        create table actionlog._livescoreAdvertising engine = myisam 
        SELECT userid, uri, time, platform_type 
        FROM actionlog.action_201506
        where time between '2015-06-11 10:30:00' and now()
        and uri like '%customTraceCode=livescoreAdvertising%';

                ALTER TABLE actionlog._livescoreAdvertising convert to character set utf8 collate utf8_general_ci;

        create table actionlog._livescoreAdvertising_1 engine = myisam 
        SELECT (case when ((b.id%20)+1>10) then 'a' else 'b' end) as g, a.userid, a.uri, a.time, a.platform_type, substr(uri,length(uri),1) as abtest
        FROM actionlog._livescoreadvertising a left join plsport_playsport.member b on a.userid = b.userid
        where a.userid <> '';

        SELECT g, abtest, count(uri) as c 
        FROM actionlog._livescoreadvertising_1
        group by g, abtest;

# 檢查購牌位置點擊的部分
        create table actionlog._livescore_LSC engine = myisam 
        SELECT userid, uri, time, platform_type 
        FROM actionlog.action_201506
        where time between '2015-06-11 10:30:00' and now()
        and uri like '%rp=LSC%';

                ALTER TABLE actionlog._livescore_LSC convert to character set utf8 collate utf8_general_ci;

        create table actionlog._livescore_LSC_1 engine = myisam
        SELECT (case when ((b.id%20)+1>10) then 'a' else 'b' end) as g, a.userid, a.uri, a.time, a.platform_type 
        FROM actionlog._livescore_lsc a left join plsport_playsport.member b on a.userid = b.userid
        where a.userid <> '';

        SELECT g, count(uri) as c 
        FROM actionlog._livescore_lsc_1
        group by g;


# 以下是abtesting分析的部分
# 先算廣告banner點擊的部分
        create table actionlog._livescoreAdvertising engine = myisam 
        SELECT userid, uri, time, platform_type 
        FROM actionlog.action_201506
        where time between '2015-06-11 10:30:00' and now()
        and uri like '%customTraceCode=livescoreAdvertising%';
        
        insert ignore into actionlog._livescoreAdvertising 
        SELECT userid, uri, time, platform_type 
        FROM actionlog.action_201507
        where time between '2015-06-11 10:30:00' and now()
        and uri like '%customTraceCode=livescoreAdvertising%';

        ALTER TABLE actionlog._livescoreAdvertising convert to character set utf8 collate utf8_general_ci;

        create table actionlog._livescoreAdvertising_1 engine = myisam 
        SELECT (case when ((b.id%20)+1>10) then 'a' else 'b' end) as g, a.userid, a.uri, a.time, a.platform_type, substr(uri,length(uri),1) as abtest
        FROM actionlog._livescoreadvertising a left join plsport_playsport.member b on a.userid = b.userid
        where a.userid <> '';

# 再算宣傳單元的部分
        create table actionlog._livescore_LSC engine = myisam 
        SELECT userid, uri, time, platform_type 
        FROM actionlog.action_201506
        where time between '2015-06-11 10:30:00' and now()
        and uri like '%rp=LSC%';

        insert ignore into actionlog._livescore_LSC  
        SELECT userid, uri, time, platform_type 
        FROM actionlog.action_201507
        where time between '2015-06-11 10:30:00' and now()
        and uri like '%rp=LSC%';

        ALTER TABLE actionlog._livescore_LSC convert to character set utf8 collate utf8_general_ci;

        create table actionlog._livescore_LSC_1 engine = myisam
        SELECT (case when ((b.id%20)+1>10) then 'a' else 'b' end) as g, a.userid, a.uri, a.time, a.platform_type 
        FROM actionlog._livescore_lsc a left join plsport_playsport.member b on a.userid = b.userid
        where a.userid <> '';


# 每100人次的點擊率大於即時比分benner廣告的點擊率 
        create table actionlog._livescore_all_traffic engine = myisam 
        SELECT userid, uri, time, platform_type 
        FROM actionlog.action_201506
        where time between '2015-06-11 10:30:00' and now()
        and uri like '%/livescore.php%' and userid <> '';
        
        insert ignore into actionlog._livescore_all_traffic 
        SELECT userid, uri, time, platform_type 
        FROM actionlog.action_201507
        where time between '2015-06-11 10:30:00' and now()
        and uri like '%/livescore.php%' and userid <> '';

        ALTER TABLE actionlog._livescore_all_traffic convert to character set utf8 collate utf8_general_ci;

        create table actionlog._livescore_all_traffic_1 engine = myisam
        SELECT (case when ((b.id%20)+1>10) then 'a' else 'b' end) as g, a.userid, a.uri, a.time, a.platform_type 
        FROM actionlog._livescore_all_traffic a left join plsport_playsport.member b on a.userid = b.userid
        where a.userid <> '';


# (1)實驗組中點banner的人數-2141
        create table actionlog._livescoreadvertising_2 engine = myisam
        SELECT userid, count(uri) as c 
        FROM actionlog._livescoreadvertising_1
        where g = 'a' and abtest = 'a'
        group by userid;

        select a.platform_type, count(a.userid) as c
        from (
            SELECT userid, platform_type, count(uri) as c 
            FROM actionlog._livescoreadvertising_1
            where g = 'a' and abtest = 'a'
            group by userid, platform_type) as a
        group by a.platform_type;

# (2)實驗組中點宣傳單元的人數-2459
        create table actionlog._livescore_lsc_2 engine = myisam
        SELECT userid, count(uri) as c 
        FROM actionlog._livescore_lsc_1
        where g = 'a'
        group by userid;
        
        select a.platform_type, count(a.userid) as c
        from (
            SELECT userid, platform_type, count(uri) as c 
            FROM actionlog._livescore_lsc_1
            where g = 'a'
            group by userid, platform_type) as a
        group by a.platform_type;
        
        
# 會後補充
create table actionlog._livescore_lsc_1_count engine = myisam
select a.d, a.platform_type, a.userid, count(a.uri) as c
from (
    SELECT userid, date(time) as d, platform_type, uri
    FROM actionlog._livescore_lsc_1) as a
group by a.d, a.platform_type, a.userid;

        SELECT d, platform_type, count(userid) as c
        FROM actionlog._livescore_lsc_1_count
        group by d, platform_type;

        SELECT d, platform_type, sum(c) as total_click 
        FROM actionlog._livescore_lsc_1_count
        group by d, platform_type;

# 6/11~7/8的所有人數
select a.platform_type, count(a.userid) as c
from (
    SELECT userid, platform_type 
    FROM actionlog._livescore_lsc_1_count
    group by userid, platform_type) as a
group by a.platform_type;


# (3)實驗組中進即時比分的人數-6498
        create table actionlog._livescore_all_traffic_2 engine = myisam
        SELECT userid, count(uri) as c 
        FROM actionlog._livescore_all_traffic_1
        where g = 'a'
        group by userid;

        select a.platform_type, count(a.userid) as c
        from (
            SELECT userid, platform_type, count(uri) as c 
            FROM actionlog._livescore_all_traffic_1
            where g = 'a'
            group by userid, platform_type) as a
        group by a.platform_type;


# 給a/b testing用 即時比PV的abtesting
create table actionlog._livescore_all_traffic_abtest engine = myisam
SELECT g as abtest, userid, count(uri) as pv 
FROM actionlog._livescore_all_traffic_1
group by g, userid;

create table actionlog._livescore_all_traffic_abtest_devices engine = myisam
SELECT g as abtest, userid, platform_type, count(uri) as pv 
FROM actionlog._livescore_all_traffic_1
group by g, userid, platform_type;

SELECT 'abtest', 'userid', 'pv' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_livescore_all_traffic_abtest.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._livescore_all_traffic_abtest);

SELECT 'abtest', 'userid', 'pv' union (
SELECT abtest, userid, pv
into outfile 'C:/Users/1-7_ASUS/Desktop/_livescore_all_traffic_abtest_1.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._livescore_all_traffic_abtest_devices
where platform_type = 1);

SELECT 'abtest', 'userid', 'pv' union (
SELECT abtest, userid, pv
into outfile 'C:/Users/1-7_ASUS/Desktop/_livescore_all_traffic_abtest_2.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._livescore_all_traffic_abtest_devices
where platform_type = 2);

SELECT 'abtest', 'userid', 'pv' union (
SELECT abtest, userid, pv
into outfile 'C:/Users/1-7_ASUS/Desktop/_livescore_all_traffic_abtest_3.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._livescore_all_traffic_abtest_devices
where platform_type = 3);



# 廣告位置點擊狀況
create table actionlog._livescore_lsc_1_all_position_click engine = myisam
SELECT g, userid, substr(uri, locate('&rp=',uri)+8, length(uri)) as rp, time, platform_type 
FROM actionlog._livescore_lsc_1
where g = 'a';

SELECT rp, substr(rp,1,1) as m, substr(rp,2,1) as n, count(userid) as c 
FROM actionlog._livescore_lsc_1_all_position_click
group by rp;

SELECT rp, substr(rp,1,1) as m, substr(rp,2,1) as n, platform_type, count(userid) as c 
FROM actionlog._livescore_lsc_1_all_position_click
group by rp, platform_type;


# 購買預測金額
SELECT * FROM plsport_playsport._predict_buyer_with_cons
where substr(position,1,1) = 'L'
order by id desc;


select a.d, sum(a.buy_price) as price
from (
    SELECT date(buy_date) as d, buy_price 
    FROM plsport_playsport._predict_buyer_with_cons
    where substr(position,1,1) = 'L'
    order by id desc) as a
group by a.d;


# =================================================================================================
#  TO eddy: (柔雅) 2015-06-12
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4428&projectId=11
# 由於第二次問卷上架的填寫人數沒有增加，
# 因此麻煩你，直接替我們分析，
# 有填答的寫手，第二題的寫文意願是否有增加，
# 規則為:
# 有回覆的使用者，對照他過去的發文情況，與他回覆願意的發文數量，
# 是否有增加，以月為單位、不分聯盟來統計。
# 問卷網址: http://psadmin.info/administration/questionnaire.php?action=previewQuestionnaire&...
# 但這個有一點急，麻煩您再回覆可以完成的時間，感謝!
# =================================================================================================

# import questionnaire_201505271339324837_answer

ALTER TABLE plsport_playsport.questionnaire_201505271339324837_answer CHANGE `1432691628` q1 INT(1);
ALTER TABLE plsport_playsport.questionnaire_201505271339324837_answer CHANGE `1432691934` q2 INT(1);

create table plsport_playsport._qu engine = myisam
SELECT userid, write_time, q1, q2 
FROM plsport_playsport.questionnaire_201505271339324837_answer;

create table plsport_playsport._analysis_post_1 engine = myisam
SELECT subjectid, allianceid, subject, postuser, substr(posttime,1,7) as ym
FROM plsport_playsport.forum
where gametype = 1;

create table plsport_playsport._analysis_post_2 engine = myisam
SELECT ym, postuser, count(subjectid) as analysis_post_count 
FROM plsport_playsport._analysis_post_1
group by ym, postuser;

create table plsport_playsport._analysis_post_3 engine = myisam
SELECT a.ym, a.postuser, a.analysis_post_count 
FROM plsport_playsport._analysis_post_2 a inner join plsport_playsport._qu b on a.postuser = b.userid;


SELECT 'ym', 'postuser', 'analysis_post_count' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_analysis_post_3.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._analysis_post_3);

SELECT 'userid', 'write_time', 'q1', 'q2' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_qu.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._qu);



# =================================================================================================
# 任務: 新增單日銷售人數最高的排行榜 [新建] (學文) 2015-06-17
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4902&projectId=11
# TO EDDY
# 要麻煩您在賺錢殺手那邊新增一個 單日銷售人數最高的排行榜
# 條件:不分聯盟，上一個月單日銷售人數最高的前五名
# 例如現在六月，要列出五月份中單日銷售人數最高的前五名，含日期、聯盟、販售人數(販售人數不含用兌換券的)
# 再麻煩您押個時間!謝謝喔!
# =================================================================================================

create table plsport_playsport._predict_seller_list_with_allianceidname_rank engine = myisam
select a.sellerid, a.nickname, a.alliancename, a.d, a.earn
from (
    SELECT sellerid, nickname, alliancename, d, sum(amount) as earn 
    FROM plsport_playsport._predict_seller_list_with_allianceidname
    group by sellerid, alliancename, d) as a
order by a.earn desc
limit 0,100;

create table plsport_playsport._predict_seller_list_with_allianceidname_rank_top10 engine = myisam
SELECT a.sellerid, a.nickname, a.alliancename, a.d, a.earn 
FROM plsport_playsport._predict_seller_list_with_allianceidname_rank a inner join 
    (SELECT sellerid, d, max(earn)
     FROM plsport_playsport._predict_seller_list_with_allianceidname_rank
     group by sellerid) as b on a.sellerid = b.sellerid and a.d = b.d
limit 0,10;

# 以上已寫成1_calculate_top30_seller_for_each_month.py
# 只要執行.py, 賺錢殺手全頁的資訊都會一起更新, 因為寫在一起

        # 2015-06-24 11:45
        # 學文 [行銷企劃]
        # TO EDDY
        # 
        # 要麻煩再新增一個  上月各聯盟銷售金額第一名，只需要聯盟、殺手名稱
        # 再麻煩了，謝謝！ 
        # 
        #     任務狀態: 重新開啟

        create table plsport_playsport._predict_seller_list_with_allianceidname_rank_top_one engine = myisam
        select a.sellerid, a.nickname, a.alliancename, a.total_sell, a.total_sell_count
        from (
            SELECT sellerid, nickname, alliancename, sum(amount) as total_sell, count(amount) as total_sell_count 
            FROM plsport_playsport._predict_seller_list_with_allianceidname
            group by sellerid, alliancename) as a inner join 
                    (select b.alliancename, max(b.total_sell) as max_sell
                        from (
                            SELECT sellerid, nickname, alliancename, sum(amount) as total_sell, count(amount) as total_sell_count 
                            FROM plsport_playsport._predict_seller_list_with_allianceidname
                            group by sellerid, alliancename) as b
                        group by b.alliancename) as c on a.alliancename = c.alliancename and a.total_sell = c.max_sell
        order by a.total_sell desc;


# =================================================================================================
# 任務: [研究]討論區的文章量是否影響業績 [新建] 2015-06-22
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4178&projectId=11
# 說明: 討論區每日的文章多寡, 是否對業績造成長期或短期(當天)影響?
# 負責人: eddy
# 研究內容:
# 
# 1. 每日的討論區文章數是否對整體業績有影響?
# 2. 各聯盟的文章數多寡是否對該聯盟的業績有影響?
# 3. 分析文會影響業績嗎? 會看分析文的人是否買更多? (ARPU提升)
# To Eddy：
# 
# 或許可以把*回文比考慮進去
# 註：回文比 = 回文總數 / 文章總數
# 任務狀態: 新建
# =================================================================================================

# part1.

create table plsport_playsport._forum engine = myisam
SELECT a.subjectid, a.subject, a.allianceid, b.alliancename, concat(a.allianceid,'_',b.alliancename) as alli, a.gametype,  a.postuser, 
       a.posttime, date(a.posttime) as d, a.viewtimes, a.replycount, a.pushcount
FROM plsport_playsport.forum a left join plsport_playsport.alliance b on a.allianceid = b.allianceid
where year(posttime) > 2012
and b.alliancename is not null
and a.gametype <> 7
and a.postuser not like '%xiaojita%'; # 亂發文機器人

ALTER TABLE plsport_playsport._forum CHANGE `gametype` `gametype` VARCHAR(15) NOT NULL;

update plsport_playsport._forum set gametype = '0_全部' where gametype = '0';
update plsport_playsport._forum set gametype = '1_分析' where gametype = '1';
update plsport_playsport._forum set gametype = '2_Live' where gametype = '2';
update plsport_playsport._forum set gametype = '3_亮單' where gametype = '3';
update plsport_playsport._forum set gametype = '4_感謝' where gametype = '4';
update plsport_playsport._forum set gametype = '8_新聞' where gametype = '8';

create table plsport_playsport._forum_all engine = myisam
SELECT d, count(subjectid) as post_count 
FROM plsport_playsport._forum
group by d;

create table plsport_playsport._forum_gametype engine = myisam
SELECT d, gametype, count(subjectid) as gametype_c 
FROM plsport_playsport._forum
group by d, gametype;

create table plsport_playsport._forum_alliance engine = myisam
SELECT d, alli, count(subjectid) as alli_count 
FROM plsport_playsport._forum
group by d, alli;

create table plsport_playsport._forum_prr engine = myisam
select a.d, a.post, a.reply, round((a.reply/a.post),1) as prr
from (
    SELECT d, count(subjectid) as post, sum(replycount) as reply 
    FROM plsport_playsport._forum
    group by d) as a;


SELECT 'subjectid', 'allianceid', 'alliancename', 'alli', 'gametype', 'postuser', 'posttime', 'd', 'viewtimes', 'replycount', 'pushcount' union (
SELECT subjectid, allianceid, alliancename, alli, gametype, postuser, posttime, d, viewtimes, replycount, pushcount
into outfile 'C:/proc/r/forum/_forum.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._forum);

SELECT 'd', 'post_count' union (
SELECT *
into outfile 'C:/proc/r/forum/_forum_all.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._forum_all);

SELECT 'd', 'gametype', 'gametype_count' union (
SELECT *
into outfile 'C:/proc/r/forum/_forum_gametype.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._forum_gametype);

SELECT 'd', 'alliance', 'alli_count' union (
SELECT *
into outfile 'C:/proc/r/forum/_forum_alliance.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._forum_alliance);

SELECT 'd', 'post', 'reply','prr' union (
SELECT *
into outfile 'C:/proc/r/forum/_forum_prr.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._forum_prr);



SELECT gametype, count(subjectid) as c 
FROM plsport_playsport._forum
group by gametype;

create table plsport_playsport._forum1 engine = myisam
SELECT subjectid, pushcount 
FROM plsport_playsport._forum;

create table plsport_playsport._forum_push_percentile engine = myisam
select subjectid, pushcount, round((cnt-rank+1)/cnt,2) as pushcount_percentile
from (SELECT subjectid, pushcount, @curRank := @curRank + 1 AS rank
      FROM plsport_playsport._forum1, (SELECT @curRank := 0) r
      order by pushcount desc) as dt,
     (select count(distinct subjectid) as cnt from plsport_playsport._forum1) as ct;

SELECT pushcount_percentile, max(pushcount) 
FROM plsport_playsport._forum_push_percentile
group by pushcount_percentile;

# 人氣推文, 全站得到推數前5%的文章
create table plsport_playsport._forum_push engine = myisam
SELECT d, count(subjectid) as good_push 
FROM plsport_playsport._forum
where pushcount>37
group by d;

SELECT 'd', 'good_push' union (
SELECT *
into outfile 'C:/proc/r/forum/_forum_push.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._forum_push);

        # update: 2015-07-14
        # 1. 是人氣推文, 但是分析文
        create table plsport_playsport._forum_push_isanalysis engine = myisam
        SELECT d, count(subjectid) as good_push_isa
        FROM plsport_playsport._forum
        where pushcount>37 and gametype = '1_分析'
        group by d;

        # 2. 是人氣推文, 但不是分析文
        create table plsport_playsport._forum_push_notanalysis engine = myisam
        SELECT d, count(subjectid) as good_push_nota 
        FROM plsport_playsport._forum
        where pushcount>37 and gametype <> '1_分析'
        group by d;


        SELECT 'd', 'good_push_isa' union (
        SELECT *
        into outfile 'C:/proc/r/forum/_forum_push_isanalysis.csv'
        fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
        FROM plsport_playsport._forum_push_isanalysis);

        SELECT 'd', 'good_push_nota' union (
        SELECT *
        into outfile 'C:/proc/r/forum/_forum_push_notanalysis.csv'
        fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
        FROM plsport_playsport._forum_push_notanalysis);



# 每個上架的預測, 總共收益多少金額
create table plsport_playsport._revenue_detail engine = myisam
SELECT id_bought, sum(buy_price) as revenue
FROM plsport_playsport.predict_buyer
group by id_bought;

        ALTER TABLE plsport_playsport.predict_seller ADD INDEX (`id`);
        ALTER TABLE plsport_playsport._revenue_detail ADD INDEX (`id_bought`);

# (a)每個上架的預測(主名單) left join 總共收益多少金額
create table plsport_playsport._seller_detail engine = myisam
SELECT a.id, a.sellerid, a.mode, a.sale_allianceid, a.sale_date, date(a.sale_date) as d, a.promotion, a.analysis_flag, a.buyer_count, a.sale_price, b.revenue
FROM plsport_playsport.predict_seller a left join plsport_playsport._revenue_detail b on a.id = b.id_bought
where date(sale_date) between '2013-01-01' and subdate(now(),1);

create table plsport_playsport._sale_all engine = myisam
SELECT sale_date, d, sellerid, mode, sale_allianceid, revenue 
FROM plsport_playsport._seller_detail;

        create table plsport_playsport._sale_all_by_all engine = myisam
        SELECT d, sum(revenue) as revenue 
        FROM plsport_playsport._sale_all
        group by d;

        create table plsport_playsport._sale_all_by_mode engine = myisam
        SELECT d, mode, sum(revenue) as revenue_by_mode
        FROM plsport_playsport._sale_all
        group by d, mode;
        
        ALTER TABLE plsport_playsport._sale_all_by_mode CHANGE `mode` `mode` VARCHAR(10) NOT NULL;
        update plsport_playsport._sale_all_by_mode set mode = '1_運彩' where mode = '1';
        update plsport_playsport._sale_all_by_mode set mode = '2_國際' where mode = '2';
        
        create table plsport_playsport._sale_all_by_allianceid engine = myisam
        SELECT d, sale_allianceid, sum(revenue) as revenue_by_allianceid
        FROM plsport_playsport._sale_all
        group by d, sale_allianceid;
        
        SELECT 'd', 'revenue' union (
        SELECT *
        into outfile 'C:/proc/r/forum/_sale_all_by_all.csv'
        fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
        FROM plsport_playsport._sale_all_by_all);

        SELECT 'd', 'mode', 'revenue' union (
        SELECT *
        into outfile 'C:/proc/r/forum/_sale_all_by_mode.csv'
        fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
        FROM plsport_playsport._sale_all_by_mode);

        SELECT 'd', 'sale_allianceid', 'revenue' union (
        SELECT *
        into outfile 'C:/proc/r/forum/_sale_all_by_allianceid.csv'
        fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
        FROM plsport_playsport._sale_all_by_allianceid);


# part2. 計算使用者看那些特定的文章

create table actionlog._action_201401_fd engine = myisam SELECT userid, uri, time FROM actionlog.action_201401 where uri like '%/forumdetail.php%' and userid <> '';
create table actionlog._action_201402_fd engine = myisam SELECT userid, uri, time FROM actionlog.action_201402 where uri like '%/forumdetail.php%' and userid <> '';
create table actionlog._action_201403_fd engine = myisam SELECT userid, uri, time FROM actionlog.action_201403 where uri like '%/forumdetail.php%' and userid <> '';
create table actionlog._action_201404_fd engine = myisam SELECT userid, uri, time FROM actionlog.action_201404 where uri like '%/forumdetail.php%' and userid <> '';
create table actionlog._action_201405_fd engine = myisam SELECT userid, uri, time FROM actionlog.action_201405 where uri like '%/forumdetail.php%' and userid <> '';
create table actionlog._action_201406_fd engine = myisam SELECT userid, uri, time FROM actionlog.action_201406 where uri like '%/forumdetail.php%' and userid <> '';
create table actionlog._action_201407_fd engine = myisam SELECT userid, uri, time FROM actionlog.action_201407 where uri like '%/forumdetail.php%' and userid <> '';
create table actionlog._action_201408_fd engine = myisam SELECT userid, uri, time FROM actionlog.action_201408 where uri like '%/forumdetail.php%' and userid <> '';
create table actionlog._action_201409_fd engine = myisam SELECT userid, uri, time FROM actionlog.action_201409 where uri like '%/forumdetail.php%' and userid <> '';
create table actionlog._action_201410_fd engine = myisam SELECT userid, uri, time FROM actionlog.action_201410 where uri like '%/forumdetail.php%' and userid <> '';
create table actionlog._action_201411_fd engine = myisam SELECT userid, uri, time FROM actionlog.action_201411 where uri like '%/forumdetail.php%' and userid <> '';
create table actionlog._action_201412_fd engine = myisam SELECT userid, uri, time FROM actionlog.action_201412 where uri like '%/forumdetail.php%' and userid <> '';
create table actionlog._action_201501_fd engine = myisam SELECT userid, uri, time FROM actionlog.action_201501 where uri like '%/forumdetail.php%' and userid <> '';
create table actionlog._action_201502_fd engine = myisam SELECT userid, uri, time FROM actionlog.action_201502 where uri like '%/forumdetail.php%' and userid <> '';
create table actionlog._action_201503_fd engine = myisam SELECT userid, uri, time FROM actionlog.action_201503 where uri like '%/forumdetail.php%' and userid <> '';
create table actionlog._action_201504_fd engine = myisam SELECT userid, uri, time FROM actionlog.action_201504 where uri like '%/forumdetail.php%' and userid <> '';
create table actionlog._action_201505_fd engine = myisam SELECT userid, uri, time FROM actionlog.action_201505 where uri like '%/forumdetail.php%' and userid <> '';
create table actionlog._action_201506_fd engine = myisam SELECT userid, uri, time FROM actionlog.action_201506 where uri like '%/forumdetail.php%' and userid <> '';
create table actionlog._action_201507_fd engine = myisam SELECT userid, uri, time FROM actionlog.action_201507 where uri like '%/forumdetail.php%' and userid <> '';

        # 單純計算每個人看了幾篇文章而已
        create table actionlog._action_201401_fg SELECT userid, count(uri) as pv FROM actionlog._action_201401_fd group by userid;
        create table actionlog._action_201402_fg SELECT userid, count(uri) as pv FROM actionlog._action_201402_fd group by userid;
        create table actionlog._action_201403_fg SELECT userid, count(uri) as pv FROM actionlog._action_201403_fd group by userid;
        create table actionlog._action_201404_fg SELECT userid, count(uri) as pv FROM actionlog._action_201404_fd group by userid;
        create table actionlog._action_201405_fg SELECT userid, count(uri) as pv FROM actionlog._action_201405_fd group by userid;
        create table actionlog._action_201406_fg SELECT userid, count(uri) as pv FROM actionlog._action_201406_fd group by userid;
        create table actionlog._action_201407_fg SELECT userid, count(uri) as pv FROM actionlog._action_201407_fd group by userid;
        create table actionlog._action_201408_fg SELECT userid, count(uri) as pv FROM actionlog._action_201408_fd group by userid;
        create table actionlog._action_201409_fg SELECT userid, count(uri) as pv FROM actionlog._action_201409_fd group by userid;
        create table actionlog._action_201410_fg SELECT userid, count(uri) as pv FROM actionlog._action_201410_fd group by userid;
        create table actionlog._action_201411_fg SELECT userid, count(uri) as pv FROM actionlog._action_201411_fd group by userid;
        create table actionlog._action_201412_fg SELECT userid, count(uri) as pv FROM actionlog._action_201412_fd group by userid;
        create table actionlog._action_201501_fg SELECT userid, count(uri) as pv FROM actionlog._action_201501_fd group by userid;
        create table actionlog._action_201502_fg SELECT userid, count(uri) as pv FROM actionlog._action_201502_fd group by userid;
        create table actionlog._action_201503_fg SELECT userid, count(uri) as pv FROM actionlog._action_201503_fd group by userid;
        create table actionlog._action_201504_fg SELECT userid, count(uri) as pv FROM actionlog._action_201504_fd group by userid;
        create table actionlog._action_201505_fg SELECT userid, count(uri) as pv FROM actionlog._action_201505_fd group by userid;
        create table actionlog._action_201506_fg SELECT userid, count(uri) as pv FROM actionlog._action_201506_fd group by userid;
        create table actionlog._action_201507_fg SELECT userid, count(uri) as pv FROM actionlog._action_201507_fd group by userid;
        
        create table actionlog._action_fg engine = myisam select * from actionlog._action_201401_fg;
        insert ignore into actionlog._action_fg select * from actionlog._action_201402_fg;
        insert ignore into actionlog._action_fg select * from actionlog._action_201403_fg;
        insert ignore into actionlog._action_fg select * from actionlog._action_201404_fg;
        insert ignore into actionlog._action_fg select * from actionlog._action_201405_fg;        
        insert ignore into actionlog._action_fg select * from actionlog._action_201406_fg;
        insert ignore into actionlog._action_fg select * from actionlog._action_201407_fg;
        insert ignore into actionlog._action_fg select * from actionlog._action_201408_fg;
        insert ignore into actionlog._action_fg select * from actionlog._action_201409_fg; 
        insert ignore into actionlog._action_fg select * from actionlog._action_201410_fg;
        insert ignore into actionlog._action_fg select * from actionlog._action_201411_fg;
        insert ignore into actionlog._action_fg select * from actionlog._action_201412_fg;
        insert ignore into actionlog._action_fg select * from actionlog._action_201501_fg; 
        insert ignore into actionlog._action_fg select * from actionlog._action_201502_fg;
        insert ignore into actionlog._action_fg select * from actionlog._action_201503_fg;
        insert ignore into actionlog._action_fg select * from actionlog._action_201504_fg;
        insert ignore into actionlog._action_fg select * from actionlog._action_201505_fg; 
        insert ignore into actionlog._action_fg select * from actionlog._action_201506_fg; 
        insert ignore into actionlog._action_fg select * from actionlog._action_201505_fg;
        
        create table actionlog._action_fg_1 engine = myisam
        SELECT userid, sum(pv) as pv 
        FROM actionlog._action_fg
        group by userid;
        
        create table plsport_playsport._customer engine = myisam
        SELECT userid, sum(amount) as spent 
        FROM plsport_playsport.pcash_log
        where payed = 1 and type = 1
        and year(date) > 2013
        group by userid;
        
        ALTER TABLE plsport_playsport._customer ADD INDEX (`userid`);
        ALTER TABLE actionlog._action_fg_1 ADD INDEX (`userid`);
        
        create table plsport_playsport._customer_1 engine = myisam
        SELECT a.userid, a.spent, b.pv 
        FROM plsport_playsport._customer a left join actionlog._action_fg_1 b on a.userid = b.userid;
        
create table actionlog._action_fs_201401 engine = myisam select a.userid, date(a.time) as d, (case when (locate('&',a.s)>0) then substr(a.s,1,locate('&',a.s)-1) else a.s end) as s
from (SELECT userid, uri, time, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._action_201401_fd) as a;
create table actionlog._action_fs_201402 engine = myisam select a.userid, date(a.time) as d, (case when (locate('&',a.s)>0) then substr(a.s,1,locate('&',a.s)-1) else a.s end) as s
from (SELECT userid, uri, time, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._action_201402_fd) as a;
create table actionlog._action_fs_201403 engine = myisam select a.userid, date(a.time) as d, (case when (locate('&',a.s)>0) then substr(a.s,1,locate('&',a.s)-1) else a.s end) as s
from (SELECT userid, uri, time, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._action_201403_fd) as a;
create table actionlog._action_fs_201404 engine = myisam select a.userid, date(a.time) as d, (case when (locate('&',a.s)>0) then substr(a.s,1,locate('&',a.s)-1) else a.s end) as s
from (SELECT userid, uri, time, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._action_201404_fd) as a;
create table actionlog._action_fs_201405 engine = myisam select a.userid, date(a.time) as d, (case when (locate('&',a.s)>0) then substr(a.s,1,locate('&',a.s)-1) else a.s end) as s
from (SELECT userid, uri, time, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._action_201405_fd) as a;
create table actionlog._action_fs_201406 engine = myisam select a.userid, date(a.time) as d, (case when (locate('&',a.s)>0) then substr(a.s,1,locate('&',a.s)-1) else a.s end) as s
from (SELECT userid, uri, time, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._action_201406_fd) as a;
create table actionlog._action_fs_201407 engine = myisam select a.userid, date(a.time) as d, (case when (locate('&',a.s)>0) then substr(a.s,1,locate('&',a.s)-1) else a.s end) as s
from (SELECT userid, uri, time, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._action_201407_fd) as a;
create table actionlog._action_fs_201408 engine = myisam select a.userid, date(a.time) as d, (case when (locate('&',a.s)>0) then substr(a.s,1,locate('&',a.s)-1) else a.s end) as s
from (SELECT userid, uri, time, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._action_201408_fd) as a;
create table actionlog._action_fs_201409 engine = myisam select a.userid, date(a.time) as d, (case when (locate('&',a.s)>0) then substr(a.s,1,locate('&',a.s)-1) else a.s end) as s
from (SELECT userid, uri, time, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._action_201409_fd) as a;
create table actionlog._action_fs_201410 engine = myisam select a.userid, date(a.time) as d, (case when (locate('&',a.s)>0) then substr(a.s,1,locate('&',a.s)-1) else a.s end) as s
from (SELECT userid, uri, time, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._action_201410_fd) as a;
create table actionlog._action_fs_201411 engine = myisam select a.userid, date(a.time) as d, (case when (locate('&',a.s)>0) then substr(a.s,1,locate('&',a.s)-1) else a.s end) as s
from (SELECT userid, uri, time, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._action_201411_fd) as a;
create table actionlog._action_fs_201412 engine = myisam select a.userid, date(a.time) as d, (case when (locate('&',a.s)>0) then substr(a.s,1,locate('&',a.s)-1) else a.s end) as s
from (SELECT userid, uri, time, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._action_201412_fd) as a;
create table actionlog._action_fs_201501 engine = myisam select a.userid, date(a.time) as d, (case when (locate('&',a.s)>0) then substr(a.s,1,locate('&',a.s)-1) else a.s end) as s
from (SELECT userid, uri, time, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._action_201501_fd) as a;
create table actionlog._action_fs_201502 engine = myisam select a.userid, date(a.time) as d, (case when (locate('&',a.s)>0) then substr(a.s,1,locate('&',a.s)-1) else a.s end) as s
from (SELECT userid, uri, time, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._action_201502_fd) as a;
create table actionlog._action_fs_201503 engine = myisam select a.userid, date(a.time) as d, (case when (locate('&',a.s)>0) then substr(a.s,1,locate('&',a.s)-1) else a.s end) as s
from (SELECT userid, uri, time, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._action_201503_fd) as a;
create table actionlog._action_fs_201504 engine = myisam select a.userid, date(a.time) as d, (case when (locate('&',a.s)>0) then substr(a.s,1,locate('&',a.s)-1) else a.s end) as s
from (SELECT userid, uri, time, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._action_201504_fd) as a;
create table actionlog._action_fs_201505 engine = myisam select a.userid, date(a.time) as d, (case when (locate('&',a.s)>0) then substr(a.s,1,locate('&',a.s)-1) else a.s end) as s
from (SELECT userid, uri, time, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._action_201505_fd) as a;
create table actionlog._action_fs_201506 engine = myisam select a.userid, date(a.time) as d, (case when (locate('&',a.s)>0) then substr(a.s,1,locate('&',a.s)-1) else a.s end) as s
from (SELECT userid, uri, time, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._action_201506_fd) as a;

ALTER TABLE actionlog._action_fs_201401 CHANGE `s` `s` CHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE actionlog._action_fs_201402 CHANGE `s` `s` CHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE actionlog._action_fs_201403 CHANGE `s` `s` CHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE actionlog._action_fs_201404 CHANGE `s` `s` CHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE actionlog._action_fs_201405 CHANGE `s` `s` CHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE actionlog._action_fs_201406 CHANGE `s` `s` CHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE actionlog._action_fs_201407 CHANGE `s` `s` CHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE actionlog._action_fs_201408 CHANGE `s` `s` CHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE actionlog._action_fs_201409 CHANGE `s` `s` CHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE actionlog._action_fs_201410 CHANGE `s` `s` CHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE actionlog._action_fs_201411 CHANGE `s` `s` CHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE actionlog._action_fs_201412 CHANGE `s` `s` CHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE actionlog._action_fs_201501 CHANGE `s` `s` CHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE actionlog._action_fs_201502 CHANGE `s` `s` CHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE actionlog._action_fs_201503 CHANGE `s` `s` CHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE actionlog._action_fs_201504 CHANGE `s` `s` CHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE actionlog._action_fs_201505 CHANGE `s` `s` CHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE actionlog._action_fs_201506 CHANGE `s` `s` CHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

create table actionlog._action_fsg_201401 engine = myisam SELECT userid, d, s FROM actionlog._action_fs_201401 group by userid, d, s;
create table actionlog._action_fsg_201402 engine = myisam SELECT userid, d, s FROM actionlog._action_fs_201402 group by userid, d, s;
create table actionlog._action_fsg_201403 engine = myisam SELECT userid, d, s FROM actionlog._action_fs_201403 group by userid, d, s;
create table actionlog._action_fsg_201404 engine = myisam SELECT userid, d, s FROM actionlog._action_fs_201404 group by userid, d, s;
create table actionlog._action_fsg_201405 engine = myisam SELECT userid, d, s FROM actionlog._action_fs_201405 group by userid, d, s;
create table actionlog._action_fsg_201406 engine = myisam SELECT userid, d, s FROM actionlog._action_fs_201406 group by userid, d, s;
create table actionlog._action_fsg_201407 engine = myisam SELECT userid, d, s FROM actionlog._action_fs_201407 group by userid, d, s;
create table actionlog._action_fsg_201408 engine = myisam SELECT userid, d, s FROM actionlog._action_fs_201408 group by userid, d, s;
create table actionlog._action_fsg_201409 engine = myisam SELECT userid, d, s FROM actionlog._action_fs_201409 group by userid, d, s;
create table actionlog._action_fsg_201410 engine = myisam SELECT userid, d, s FROM actionlog._action_fs_201410 group by userid, d, s;
create table actionlog._action_fsg_201411 engine = myisam SELECT userid, d, s FROM actionlog._action_fs_201411 group by userid, d, s;
create table actionlog._action_fsg_201412 engine = myisam SELECT userid, d, s FROM actionlog._action_fs_201412 group by userid, d, s;
create table actionlog._action_fsg_201501 engine = myisam SELECT userid, d, s FROM actionlog._action_fs_201501 group by userid, d, s;
create table actionlog._action_fsg_201502 engine = myisam SELECT userid, d, s FROM actionlog._action_fs_201502 group by userid, d, s;
create table actionlog._action_fsg_201503 engine = myisam SELECT userid, d, s FROM actionlog._action_fs_201503 group by userid, d, s;
create table actionlog._action_fsg_201504 engine = myisam SELECT userid, d, s FROM actionlog._action_fs_201504 group by userid, d, s;
create table actionlog._action_fsg_201505 engine = myisam SELECT userid, d, s FROM actionlog._action_fs_201505 group by userid, d, s;
create table actionlog._action_fsg_201506 engine = myisam SELECT userid, d, s FROM actionlog._action_fs_201506 group by userid, d, s;

        ALTER TABLE plsport_playsport._forum ADD INDEX (`subjectid`);
        ALTER TABLE actionlog._action_fsg_201401 ADD INDEX (`s`);
        ALTER TABLE actionlog._action_fsg_201402 ADD INDEX (`s`);
        ALTER TABLE actionlog._action_fsg_201403 ADD INDEX (`s`);
        ALTER TABLE actionlog._action_fsg_201404 ADD INDEX (`s`);
        ALTER TABLE actionlog._action_fsg_201405 ADD INDEX (`s`);
        ALTER TABLE actionlog._action_fsg_201406 ADD INDEX (`s`);
        ALTER TABLE actionlog._action_fsg_201407 ADD INDEX (`s`);
        ALTER TABLE actionlog._action_fsg_201408 ADD INDEX (`s`);
        ALTER TABLE actionlog._action_fsg_201409 ADD INDEX (`s`);
        ALTER TABLE actionlog._action_fsg_201410 ADD INDEX (`s`);
        ALTER TABLE actionlog._action_fsg_201411 ADD INDEX (`s`);
        ALTER TABLE actionlog._action_fsg_201412 ADD INDEX (`s`);
        ALTER TABLE actionlog._action_fsg_201501 ADD INDEX (`s`);
        ALTER TABLE actionlog._action_fsg_201502 ADD INDEX (`s`);
        ALTER TABLE actionlog._action_fsg_201503 ADD INDEX (`s`);
        ALTER TABLE actionlog._action_fsg_201504 ADD INDEX (`s`);
        ALTER TABLE actionlog._action_fsg_201505 ADD INDEX (`s`);
        ALTER TABLE actionlog._action_fsg_201506 ADD INDEX (`s`);

create table actionlog._action_fsgs_201401 engine = myisam SELECT a.userid, a.d, a.s, b.alli, b.gametype FROM actionlog._action_fsg_201401 a left join plsport_playsport._forum b on a.s = b.subjectid;
create table actionlog._action_fsgs_201402 engine = myisam SELECT a.userid, a.d, a.s, b.alli, b.gametype FROM actionlog._action_fsg_201402 a left join plsport_playsport._forum b on a.s = b.subjectid;
create table actionlog._action_fsgs_201403 engine = myisam SELECT a.userid, a.d, a.s, b.alli, b.gametype FROM actionlog._action_fsg_201403 a left join plsport_playsport._forum b on a.s = b.subjectid;
create table actionlog._action_fsgs_201404 engine = myisam SELECT a.userid, a.d, a.s, b.alli, b.gametype FROM actionlog._action_fsg_201404 a left join plsport_playsport._forum b on a.s = b.subjectid;
create table actionlog._action_fsgs_201405 engine = myisam SELECT a.userid, a.d, a.s, b.alli, b.gametype FROM actionlog._action_fsg_201405 a left join plsport_playsport._forum b on a.s = b.subjectid;
create table actionlog._action_fsgs_201406 engine = myisam SELECT a.userid, a.d, a.s, b.alli, b.gametype FROM actionlog._action_fsg_201406 a left join plsport_playsport._forum b on a.s = b.subjectid;
create table actionlog._action_fsgs_201407 engine = myisam SELECT a.userid, a.d, a.s, b.alli, b.gametype FROM actionlog._action_fsg_201407 a left join plsport_playsport._forum b on a.s = b.subjectid;
create table actionlog._action_fsgs_201408 engine = myisam SELECT a.userid, a.d, a.s, b.alli, b.gametype FROM actionlog._action_fsg_201408 a left join plsport_playsport._forum b on a.s = b.subjectid;
create table actionlog._action_fsgs_201409 engine = myisam SELECT a.userid, a.d, a.s, b.alli, b.gametype FROM actionlog._action_fsg_201409 a left join plsport_playsport._forum b on a.s = b.subjectid;
create table actionlog._action_fsgs_201410 engine = myisam SELECT a.userid, a.d, a.s, b.alli, b.gametype FROM actionlog._action_fsg_201410 a left join plsport_playsport._forum b on a.s = b.subjectid;
create table actionlog._action_fsgs_201411 engine = myisam SELECT a.userid, a.d, a.s, b.alli, b.gametype FROM actionlog._action_fsg_201411 a left join plsport_playsport._forum b on a.s = b.subjectid;
create table actionlog._action_fsgs_201412 engine = myisam SELECT a.userid, a.d, a.s, b.alli, b.gametype FROM actionlog._action_fsg_201412 a left join plsport_playsport._forum b on a.s = b.subjectid;
create table actionlog._action_fsgs_201501 engine = myisam SELECT a.userid, a.d, a.s, b.alli, b.gametype FROM actionlog._action_fsg_201401 a left join plsport_playsport._forum b on a.s = b.subjectid;
create table actionlog._action_fsgs_201502 engine = myisam SELECT a.userid, a.d, a.s, b.alli, b.gametype FROM actionlog._action_fsg_201402 a left join plsport_playsport._forum b on a.s = b.subjectid;
create table actionlog._action_fsgs_201503 engine = myisam SELECT a.userid, a.d, a.s, b.alli, b.gametype FROM actionlog._action_fsg_201403 a left join plsport_playsport._forum b on a.s = b.subjectid;
create table actionlog._action_fsgs_201504 engine = myisam SELECT a.userid, a.d, a.s, b.alli, b.gametype FROM actionlog._action_fsg_201404 a left join plsport_playsport._forum b on a.s = b.subjectid;
create table actionlog._action_fsgs_201505 engine = myisam SELECT a.userid, a.d, a.s, b.alli, b.gametype FROM actionlog._action_fsg_201405 a left join plsport_playsport._forum b on a.s = b.subjectid;
create table actionlog._action_fsgs_201506 engine = myisam SELECT a.userid, a.d, a.s, b.alli, b.gametype FROM actionlog._action_fsg_201406 a left join plsport_playsport._forum b on a.s = b.subjectid;

        ALTER TABLE actionlog._action_fsgs_201401 ADD INDEX (`userid`,`alli`,`gametype`);
        ALTER TABLE actionlog._action_fsgs_201402 ADD INDEX (`userid`,`alli`,`gametype`);
        ALTER TABLE actionlog._action_fsgs_201403 ADD INDEX (`userid`,`alli`,`gametype`);
        ALTER TABLE actionlog._action_fsgs_201404 ADD INDEX (`userid`,`alli`,`gametype`);
        ALTER TABLE actionlog._action_fsgs_201405 ADD INDEX (`userid`,`alli`,`gametype`);
        ALTER TABLE actionlog._action_fsgs_201406 ADD INDEX (`userid`,`alli`,`gametype`);
        ALTER TABLE actionlog._action_fsgs_201407 ADD INDEX (`userid`,`alli`,`gametype`);
        ALTER TABLE actionlog._action_fsgs_201408 ADD INDEX (`userid`,`alli`,`gametype`);
        ALTER TABLE actionlog._action_fsgs_201409 ADD INDEX (`userid`,`alli`,`gametype`);
        ALTER TABLE actionlog._action_fsgs_201410 ADD INDEX (`userid`,`alli`,`gametype`);
        ALTER TABLE actionlog._action_fsgs_201411 ADD INDEX (`userid`,`alli`,`gametype`);
        ALTER TABLE actionlog._action_fsgs_201412 ADD INDEX (`userid`,`alli`,`gametype`);
        ALTER TABLE actionlog._action_fsgs_201501 ADD INDEX (`userid`,`alli`,`gametype`);
        ALTER TABLE actionlog._action_fsgs_201502 ADD INDEX (`userid`,`alli`,`gametype`);
        ALTER TABLE actionlog._action_fsgs_201503 ADD INDEX (`userid`,`alli`,`gametype`);
        ALTER TABLE actionlog._action_fsgs_201504 ADD INDEX (`userid`,`alli`,`gametype`);
        ALTER TABLE actionlog._action_fsgs_201505 ADD INDEX (`userid`,`alli`,`gametype`);
        ALTER TABLE actionlog._action_fsgs_201506 ADD INDEX (`userid`,`alli`,`gametype`);

create table actionlog._action_fsgsf_201401 engine = myisam SELECT userid, d, alli, gametype, count(s) as view_count FROM actionlog._action_fsgs_201401 where alli is not null group by userid, d, alli, gametype;
create table actionlog._action_fsgsf_201402 engine = myisam SELECT userid, d, alli, gametype, count(s) as view_count FROM actionlog._action_fsgs_201402 where alli is not null group by userid, d, alli, gametype;
create table actionlog._action_fsgsf_201403 engine = myisam SELECT userid, d, alli, gametype, count(s) as view_count FROM actionlog._action_fsgs_201403 where alli is not null group by userid, d, alli, gametype;
create table actionlog._action_fsgsf_201404 engine = myisam SELECT userid, d, alli, gametype, count(s) as view_count FROM actionlog._action_fsgs_201404 where alli is not null group by userid, d, alli, gametype;
create table actionlog._action_fsgsf_201405 engine = myisam SELECT userid, d, alli, gametype, count(s) as view_count FROM actionlog._action_fsgs_201405 where alli is not null group by userid, d, alli, gametype;
create table actionlog._action_fsgsf_201406 engine = myisam SELECT userid, d, alli, gametype, count(s) as view_count FROM actionlog._action_fsgs_201406 where alli is not null group by userid, d, alli, gametype;
create table actionlog._action_fsgsf_201407 engine = myisam SELECT userid, d, alli, gametype, count(s) as view_count FROM actionlog._action_fsgs_201407 where alli is not null group by userid, d, alli, gametype;
create table actionlog._action_fsgsf_201408 engine = myisam SELECT userid, d, alli, gametype, count(s) as view_count FROM actionlog._action_fsgs_201408 where alli is not null group by userid, d, alli, gametype;
create table actionlog._action_fsgsf_201409 engine = myisam SELECT userid, d, alli, gametype, count(s) as view_count FROM actionlog._action_fsgs_201409 where alli is not null group by userid, d, alli, gametype;
create table actionlog._action_fsgsf_201410 engine = myisam SELECT userid, d, alli, gametype, count(s) as view_count FROM actionlog._action_fsgs_201410 where alli is not null group by userid, d, alli, gametype;
create table actionlog._action_fsgsf_201411 engine = myisam SELECT userid, d, alli, gametype, count(s) as view_count FROM actionlog._action_fsgs_201411 where alli is not null group by userid, d, alli, gametype;
create table actionlog._action_fsgsf_201412 engine = myisam SELECT userid, d, alli, gametype, count(s) as view_count FROM actionlog._action_fsgs_201412 where alli is not null group by userid, d, alli, gametype;
create table actionlog._action_fsgsf_201501 engine = myisam SELECT userid, d, alli, gametype, count(s) as view_count FROM actionlog._action_fsgs_201501 where alli is not null group by userid, d, alli, gametype;
create table actionlog._action_fsgsf_201502 engine = myisam SELECT userid, d, alli, gametype, count(s) as view_count FROM actionlog._action_fsgs_201502 where alli is not null group by userid, d, alli, gametype;
create table actionlog._action_fsgsf_201503 engine = myisam SELECT userid, d, alli, gametype, count(s) as view_count FROM actionlog._action_fsgs_201503 where alli is not null group by userid, d, alli, gametype;
create table actionlog._action_fsgsf_201504 engine = myisam SELECT userid, d, alli, gametype, count(s) as view_count FROM actionlog._action_fsgs_201504 where alli is not null group by userid, d, alli, gametype;
create table actionlog._action_fsgsf_201505 engine = myisam SELECT userid, d, alli, gametype, count(s) as view_count FROM actionlog._action_fsgs_201505 where alli is not null group by userid, d, alli, gametype;
create table actionlog._action_fsgsf_201506 engine = myisam SELECT userid, d, alli, gametype, count(s) as view_count FROM actionlog._action_fsgs_201506 where alli is not null group by userid, d, alli, gametype;

        create table plsport_playsport._spent_list engine = myisam
        SELECT userid, sum(amount) as spent 
        FROM plsport_playsport.pcash_log
        where payed = 1 and type = 1
        and year(date) > 2013
        group by userid;

        ALTER TABLE plsport_playsport._spent_list ADD INDEX (`userid`);
        ALTER TABLE actionlog._action_fsgsf_201401 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._action_fsgsf_201402 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._action_fsgsf_201403 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._action_fsgsf_201404 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._action_fsgsf_201405 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._action_fsgsf_201406 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._action_fsgsf_201407 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._action_fsgsf_201408 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._action_fsgsf_201409 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._action_fsgsf_201410 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._action_fsgsf_201411 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._action_fsgsf_201412 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._action_fsgsf_201501 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._action_fsgsf_201502 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._action_fsgsf_201503 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._action_fsgsf_201504 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._action_fsgsf_201505 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._action_fsgsf_201506 convert to character set utf8 collate utf8_general_ci;


create table actionlog._action_fsgsfs engine = myisam SELECT a.userid, a.alli, a.gametype, sum(a.view_count) as view_count 
FROM actionlog._action_fsgsf_201401 a inner join plsport_playsport._spent_list b on a.userid = b.userid group by a.userid, a.alli, a.gametype;
insert ignore into actionlog._action_fsgsfs SELECT a.userid, a.alli, a.gametype, sum(a.view_count) as view_count 
FROM actionlog._action_fsgsf_201402 a inner join plsport_playsport._spent_list b on a.userid = b.userid group by a.userid, a.alli, a.gametype;
insert ignore into actionlog._action_fsgsfs SELECT a.userid, a.alli, a.gametype, sum(a.view_count) as view_count 
FROM actionlog._action_fsgsf_201403 a inner join plsport_playsport._spent_list b on a.userid = b.userid group by a.userid, a.alli, a.gametype;
insert ignore into actionlog._action_fsgsfs SELECT a.userid, a.alli, a.gametype, sum(a.view_count) as view_count 
FROM actionlog._action_fsgsf_201404 a inner join plsport_playsport._spent_list b on a.userid = b.userid group by a.userid, a.alli, a.gametype;
insert ignore into actionlog._action_fsgsfs SELECT a.userid, a.alli, a.gametype, sum(a.view_count) as view_count 
FROM actionlog._action_fsgsf_201405 a inner join plsport_playsport._spent_list b on a.userid = b.userid group by a.userid, a.alli, a.gametype;
insert ignore into actionlog._action_fsgsfs SELECT a.userid, a.alli, a.gametype, sum(a.view_count) as view_count 
FROM actionlog._action_fsgsf_201406 a inner join plsport_playsport._spent_list b on a.userid = b.userid group by a.userid, a.alli, a.gametype;
insert ignore into actionlog._action_fsgsfs SELECT a.userid, a.alli, a.gametype, sum(a.view_count) as view_count 
FROM actionlog._action_fsgsf_201407 a inner join plsport_playsport._spent_list b on a.userid = b.userid group by a.userid, a.alli, a.gametype;
insert ignore into actionlog._action_fsgsfs SELECT a.userid, a.alli, a.gametype, sum(a.view_count) as view_count 
FROM actionlog._action_fsgsf_201408 a inner join plsport_playsport._spent_list b on a.userid = b.userid group by a.userid, a.alli, a.gametype;
insert ignore into actionlog._action_fsgsfs SELECT a.userid, a.alli, a.gametype, sum(a.view_count) as view_count 
FROM actionlog._action_fsgsf_201409 a inner join plsport_playsport._spent_list b on a.userid = b.userid group by a.userid, a.alli, a.gametype;
insert ignore into actionlog._action_fsgsfs SELECT a.userid, a.alli, a.gametype, sum(a.view_count) as view_count 
FROM actionlog._action_fsgsf_201410 a inner join plsport_playsport._spent_list b on a.userid = b.userid group by a.userid, a.alli, a.gametype;
insert ignore into actionlog._action_fsgsfs SELECT a.userid, a.alli, a.gametype, sum(a.view_count) as view_count 
FROM actionlog._action_fsgsf_201411 a inner join plsport_playsport._spent_list b on a.userid = b.userid group by a.userid, a.alli, a.gametype;
insert ignore into actionlog._action_fsgsfs SELECT a.userid, a.alli, a.gametype, sum(a.view_count) as view_count 
FROM actionlog._action_fsgsf_201412 a inner join plsport_playsport._spent_list b on a.userid = b.userid group by a.userid, a.alli, a.gametype;
insert ignore into actionlog._action_fsgsfs SELECT a.userid, a.alli, a.gametype, sum(a.view_count) as view_count 
FROM actionlog._action_fsgsf_201501 a inner join plsport_playsport._spent_list b on a.userid = b.userid group by a.userid, a.alli, a.gametype;
insert ignore into actionlog._action_fsgsfs SELECT a.userid, a.alli, a.gametype, sum(a.view_count) as view_count 
FROM actionlog._action_fsgsf_201502 a inner join plsport_playsport._spent_list b on a.userid = b.userid group by a.userid, a.alli, a.gametype;
insert ignore into actionlog._action_fsgsfs SELECT a.userid, a.alli, a.gametype, sum(a.view_count) as view_count 
FROM actionlog._action_fsgsf_201503 a inner join plsport_playsport._spent_list b on a.userid = b.userid group by a.userid, a.alli, a.gametype;
insert ignore into actionlog._action_fsgsfs SELECT a.userid, a.alli, a.gametype, sum(a.view_count) as view_count 
FROM actionlog._action_fsgsf_201504 a inner join plsport_playsport._spent_list b on a.userid = b.userid group by a.userid, a.alli, a.gametype;
insert ignore into actionlog._action_fsgsfs SELECT a.userid, a.alli, a.gametype, sum(a.view_count) as view_count 
FROM actionlog._action_fsgsf_201505 a inner join plsport_playsport._spent_list b on a.userid = b.userid group by a.userid, a.alli, a.gametype;
insert ignore into actionlog._action_fsgsfs SELECT a.userid, a.alli, a.gametype, sum(a.view_count) as view_count 
FROM actionlog._action_fsgsf_201506 a inner join plsport_playsport._spent_list b on a.userid = b.userid group by a.userid, a.alli, a.gametype;

create table actionlog._action_fsgsfs_1 engine = myisam
SELECT userid, alli, gametype, sum(view_count) as view_count 
FROM actionlog._action_fsgsfs
group by userid, alli, gametype;

create table actionlog._action_fsgsfs_1_by_all engine = myisam
SELECT userid, sum(view_count) as view_count 
FROM actionlog._action_fsgsfs_1
group by userid;

create table actionlog._action_fsgsfs_1_by_gametype engine = myisam
SELECT userid, gametype, sum(view_count) as view_count 
FROM actionlog._action_fsgsfs_1
group by userid, gametype;

create table actionlog._action_fsgsfs_1_by_alliance engine = myisam
SELECT userid, alli, sum(view_count) as view_count 
FROM actionlog._action_fsgsfs_1
group by userid, alli;


SELECT 'userid', 'spent'union (
SELECT *
into outfile 'C:/proc/r/forum/_spent_list.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._spent_list);

SELECT 'userid', 'count_all' union (
SELECT *
into outfile 'C:/proc/r/forum/_action_fsgsfs_1_by_all.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._action_fsgsfs_1_by_all);

SELECT 'userid', 'gametype', 'count_gametype' union (
SELECT *
into outfile 'C:/proc/r/forum/_action_fsgsfs_1_by_gametype.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._action_fsgsfs_1_by_gametype);

SELECT 'userid', 'alliance', 'count_alliance' union (
SELECT *
into outfile 'C:/proc/r/forum/_action_fsgsfs_1_by_alliance.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._action_fsgsfs_1_by_alliance);



# =================================================================================================
# 任務: [201506-A-2] 討論區文章搜尋 - 電訪名單 [新建] (阿達) 2015-07-01
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4934&projectId=11
# 說明
# 提供電訪名單
# 負責人：Eddy
# 時間：
#
# 1. 電訪名單
# 條件：
# 問卷第一題回答需要或非常需要
# 近一個月討論區pv前50%
# 欄位：
# 帳號、暱稱、討論區pv及全站佔比、手機/電腦使用比例、問卷第一題答案
# http://www.playsport.cc/questionnaire.php?question=201506031444432350&action=statistics
# =================================================================================================

create table actionlog._forum_201506 engine = myisam
SELECT userid, uri, time, (case when (platform_type=2) then 'mobile' else 'pc' end) as p
FROM actionlog.action_201506 where userid <> '' and uri like '%/forum%';
create table actionlog._forum_201507 engine = myisam
SELECT userid, uri, time, (case when (platform_type=2) then 'mobile' else 'pc' end) as p
FROM actionlog.action_201507 where userid <> '' and uri like '%/forum%';

create table actionlog._forum engine = myisam select * from actionlog._forum_201506;
insert ignore into actionlog._forum select * from actionlog._forum_201507;

create table actionlog._forum_1 engine = myisam
SELECT * 
FROM actionlog._forum
where time between subdate(now(),31) and now();

create table actionlog._forum_2 engine = myisam
SELECT userid, p, count(p) as pv
FROM actionlog._forum_1
group by userid, p;

create table actionlog._forum_3 engine = myisam
select a.userid, sum(a.pc) as pc, sum(a.mobile) as mobile
from (
    SELECT userid, (case when (p='pc') then pv else 0 end) as pc,
                   (case when (p='mobile') then pv else 0 end) as mobile
    FROM actionlog._forum_2) as a
group by a.userid;

create table actionlog._forum_4 engine = myisam
SELECT userid, (pc+mobile) as pv, round((pc/(pc+mobile)),3) as pc_p, round((mobile/(pc+mobile)),3) as mobile_p
FROM actionlog._forum_3;

create table actionlog._forum_5 engine = myisam
select userid, pv, round((cnt-rank+1)/cnt,2) as pv_percentile, pc_p, mobile_p
from (SELECT userid, pv, @curRank := @curRank + 1 AS rank, pc_p, mobile_p
      FROM actionlog._forum_4, (SELECT @curRank := 0) r
      order by pv desc) as dt,
     (select count(distinct userid) as cnt from actionlog._forum_4) as ct;

        ALTER TABLE actionlog._forum_5 convert to character set utf8 collate utf8_general_ci;

create table actionlog._forum_6 engine = myisam
SELECT a.userid, b.nickname, a.pv, a.pv_percentile, a.pc_p, a.mobile_p
FROM actionlog._forum_5 a left join plsport_playsport.member b on a.userid = b.userid;

        create table plsport_playsport._qu engine = myisam
        SELECT userid,  `1433313772` as q
        FROM plsport_playsport.questionnaire_201506031444432350_answer;

        # 最近一次的登入時間
        CREATE TABLE plsport_playsport._last_login_time engine = myisam
        SELECT userid, max(signin_time) as last_login
        FROM plsport_playsport.member_signin_log_archive
        GROUP BY userid;
        
        ALTER TABLE plsport_playsport._last_login_time convert to character set utf8 collate utf8_general_ci;

create table actionlog._forum_7 engine = myisam
SELECT a.userid, a.nickname, a.pv, a.pv_percentile, a.pc_p, a.mobile_p, b.q
FROM actionlog._forum_6 a left join plsport_playsport._qu b on a.userid = b.userid
where b.q in (1,2)
order by pv desc;

        ALTER TABLE actionlog._forum_7 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._forum_7 ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._last_login_time ADD INDEX (`userid`);
        
create table actionlog._forum_8 engine = myisam
SELECT a.userid, a.nickname, a.pv, a.pv_percentile, a.pc_p, a.mobile_p, a.q, date(b.last_login) as last_login
from actionlog._forum_7 a left join plsport_playsport._last_login_time b on a.userid = b.userid
where a.pv_percentile>0.49;

        ALTER TABLE actionlog._forum_8 CHANGE `q` `q` VARCHAR(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL;
        update actionlog._forum_8 set q = '非常需要' where q = '1';
        update actionlog._forum_8 set q = '需要'     where q = '2';

# 帳號、暱稱、討論區pv及全站佔比、手機/電腦使用比例、問卷第一題答案


SELECT 'userid', '暱稱', '討論區pv', '全站佔比','電腦使用比例','手機使用比例','問券答案','最後一次登入' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_forum_8.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._forum_8);



# =================================================================================================
# 任務: [201410-B-5] 棒球即時比分賽事數據 - 分析使用狀況 [新建] 阿達 2015-06-18 09:36
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4878&projectId=11
# 說明
# 統計MLB即時比分投打數據使用狀況
# 負責人：Eddy
# 時間：
# 
# 7/15 第一次報告
# 8/15 第二次報告
# 9/15 第三次報告 
# 內容
# 1. MLB投打數據點擊量
# a. 統計使用人數、次數、比例
# =================================================================================================


# (1)先撈出所有即時比分的pv
CREATE TABLE actionlog._livescore engine = myisam SELECT userid, uri, time FROM actionlog.action_201506 WHERE uri LIKE '%/livescore%' and userid <> '';
INSERT IGNORE INTO actionlog._livescore SELECT userid, uri, time FROM actionlog.action_201507 WHERE uri LIKE '%/livescore%' and userid <> '';
INSERT IGNORE INTO actionlog._livescore SELECT userid, uri, time FROM actionlog.action_201508 WHERE uri LIKE '%/livescore%' and userid <> '';
INSERT IGNORE INTO actionlog._livescore SELECT userid, uri, time FROM actionlog.action_201509 WHERE uri LIKE '%/livescore%' and userid <> '';

CREATE TABLE actionlog._livescore_1 engine = myisam
select a.userid, a.uri, a.time, (case when (locate('&',a.p)=0) then a.p else substr(a.p,1,locate('&',a.p)-1) end) as p
from (
    SELECT userid, uri, time, (case when (locate('aid=',uri) = 0) then 0 else substr(uri, locate('aid=',uri)+4, length(uri)) end) as p
    FROM actionlog._livescore) as a;

CREATE TABLE actionlog._livescore_2 engine = myisam
select a.d, a.userid, count(a.uri) as c
from (
    SELECT date(time) as d, uri, userid
    FROM actionlog._livescore_1
    where time between '2015-06-16 18:00:00' and now()
    and p in (0,1)) as a
group by a.d, a.userid;

# 有用即時比分的人數(限有登入)
SELECT d, count(userid) as user_count 
FROM actionlog._livescore_2
group by d;

create table plsport_playsport._events engine = myisam 
SELECT * FROM plsport_playsport.events
where name like '%livescore_game_stats%'
and time between '2015-06-16 18:00:00' and now()
and userid <> ''
order by id desc;

# 使用人數 
select b.d, count(b.userid) as user_count
from (
    select a.d, a.userid, count(a.name) as c
    from (
        SELECT date(time) as d, platform_type, name, userid
        FROM plsport_playsport._events
        where name like '%open%') as a
    group by a.d, a.userid) as b
group by b.d;

# 使用次數 
select a.d, count(a.name) as click_count
from (
    SELECT date(time) as d, platform_type, name, userid
    FROM plsport_playsport._events
    where name like '%open%') as a
group by a.d;



# =================================================================================================
# 分析文等級制度-數據撈取 2015-07-15
# http://redmine.playsport.cc/issues/50
# 
# 麻煩協助撈取推數&瀏覽數的資料
# 時間區間:2014/07~2015/06
# 條件:這段時間內有發表分析文的使用者
# 撈取項目:
# 1:不重複瀏覽數
# 每月、每人的分析文瀏覽數
# 2.推數
# 每月、每人的總推數
# 以上，麻煩請製作兩個版本:1.全站版 2.分聯盟版(指定聯盟: MLB、NBA、日棒、韓棒、中職、足球)
# 請再回覆可以提供的時間，感謝!
# 任務規劃https://docs.google.com/document/d/1pmtl-CSWGlPrSq_16G0ej-z0DWXXnZkLWqLWPItnIsY/edit
# =================================================================================================

create table plsport_playsport._analysis engine = myisam
SELECT subjectid, allianceid, postuser, posttime, substr(posttime,1,7) as ym, viewtimes, replycount, pushcount 
FROM plsport_playsport.forum
where gametype = 1
and posttime between '2014-07-01 00:00:00' and '2015-06-30 23:59:59'
and allianceid in (1,2,3,4,9,6);

create table plsport_playsport._analysis_all engine = myisam
SELECT postuser, ym, sum(viewtimes) as vt, sum(pushcount) as push
FROM plsport_playsport._analysis
group by postuser, ym;

create table plsport_playsport._analysis_by_allianceid engine = myisam
SELECT postuser, ym, allianceid, sum(viewtimes) as vt, sum(pushcount) as push
FROM plsport_playsport._analysis
group by postuser, ym, allianceid;


# 以下寫成redmine_task50.py
# 直接執行redmine_task50.py就可以了

SELECT 'allianceid', 'ym', 'vt_percentile', 'vt' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_analysis_by_allianceid_all_vt.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._analysis_by_allianceid_all_vt);

SELECT 'allianceid', 'ym', 'push_percentile', 'push' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_analysis_by_allianceid_all_push.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._analysis_by_allianceid_all_push);

SELECT  'ym', 'vt_percentile', 'vt' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_analysis_all_vt.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._analysis_all_vt);

SELECT  'ym', 'push_percentile', 'push' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_analysis_all_push.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._analysis_all_push);


# 是由 黃 雅雅 於 3 天 前更新 2015-07-27
# 
# 接下來，要發送問卷給寫手，詢問意願，
# 目標是詢問會寫分析文的寫手的意願，
# 撈選條件為:近2年內，曾經發表3篇以上分析文的人，
# 
# 你覺得如何?有達到想要的人嗎?
# 
# TOeddy:
# 
# 根據剛剛討論的，撈取條件為:近三年內、發表過三篇分析文的使用者。
# 再麻煩回覆可以完成的時間，感謝!

create table plsport_playsport._analysis_post_writer engine = myisam
SELECT subjectid, subject,allianceid, gametype, postuser, posttime  
FROM plsport_playsport.forum
where gametype = 1
and posttime between subdate(now(),1100) and now(); #近3年

create table plsport_playsport._analysis_post_writer_1 engine = myisam
select b.postuser, c.nickname, b.post_count
from (
    select a.postuser, a.post_count
    from (
        SELECT postuser, count(subject) as post_count 
        FROM plsport_playsport._analysis_post_writer
        group by postuser) as a
    where a.post_count >= 3
    order by a.post_count desc) as b left join plsport_playsport.member as c on b.postuser = c.userid;


SELECT '發文者', '匿稱', '分析文數' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_analysis_post_writer.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._analysis_post_writer_1);

SELECT postuser
into outfile 'C:/Users/1-7_ASUS/Desktop/_analysis_post_writer_for_engineer.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._analysis_post_writer_1;




# =================================================================================================
# 研究消費者使用購牌相關功能對業績的影響 (阿達) 2015-07-20
# http://redmine.playsport.cc/issues/28
# 負責人：Eddy
# 購牌相關功能
# 1. 明燈
# 2. 合牌小幫手
# 3. 購牌清單
# 4. 玩家搜尋
# 5. 個人戰績頁
# 6. 購牌專區 ( 莊家殺手/單場殺手)
# 7. 勝率榜/主推榜
# 8. 頭三標
# 9. 首頁
# 10. 討論區
# =================================================================================================


# 處理rp的部分
create table actionlog._rp_201505 SELECT userid, uri, time, platform_type FROM actionlog.action_201505 where uri like '%rp=%';
create table actionlog._rp_201506 SELECT userid, uri, time, platform_type FROM actionlog.action_201506 where uri like '%rp=%';
create table actionlog._rp_201507 SELECT userid, uri, time, platform_type FROM actionlog.action_201507 where uri like '%rp=%';

create table actionlog._rp_201505_1 engine = myisam
SELECT userid, uri, time, platform_type, substr(uri, locate('&rp=',uri)+4, length(uri)) as p FROM actionlog._rp_201505 where userid <> '';
create table actionlog._rp_201506_1 engine = myisam
SELECT userid, uri, time, platform_type, substr(uri, locate('&rp=',uri)+4, length(uri)) as p FROM actionlog._rp_201506 where userid <> '';
create table actionlog._rp_201507_1 engine = myisam
SELECT userid, uri, time, platform_type, substr(uri, locate('&rp=',uri)+4, length(uri)) as p FROM actionlog._rp_201507 where userid <> '';

create table actionlog._rp engine = myisam
SELECT userid, uri, time, platform_type, (case when (locate('&',p)=0) then p else substr(p,1,locate('&',p)-1) end) as p FROM actionlog._rp_201505_1;
insert ignore into actionlog._rp
SELECT userid, uri, time, platform_type, (case when (locate('&',p)=0) then p else substr(p,1,locate('&',p)-1) end) as p FROM actionlog._rp_201506_1;
insert ignore into actionlog._rp
SELECT userid, uri, time, platform_type, (case when (locate('&',p)=0) then p else substr(p,1,locate('&',p)-1) end) as p FROM actionlog._rp_201507_1;

        ALTER TABLE actionlog._rp CHANGE `p` `p` VARCHAR(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE actionlog._rp ADD INDEX (`p`);

# 所有的位置
SELECT p, count(uri) 
FROM actionlog._rp
where locate('%',p) = 0
and locate('+',p)=0
and locate('#',p)=0
and locate('.',p)=0
and locate('=',p)=0
and locate('?',p)=0
group by p;

# 完成
create table actionlog._rp_1 engine = myisam
SELECT userid, uri, time, platform_type, substr(p,1,3) as rp 
FROM actionlog._rp
where locate('%',p) = 0
and locate('+',p)=0
and locate('#',p)=0
and locate('.',p)=0
and locate('=',p)=0
and locate('?',p)=0;


update actionlog._rp_1 set rp='HT_' where rp='HT1';
update actionlog._rp_1 set rp='HT_' where rp='HT2';
update actionlog._rp_1 set rp='HT_' where rp='HT3';
update actionlog._rp_1 set rp='BZ_' where rp='BZR';
update actionlog._rp_1 set rp='USE' where rp='US_';

create table actionlog._rp_2 engine = myisam
SELECT userid, rp, count(uri) as c 
FROM actionlog._rp_1
where rp not in ('MSA','MFA','MSI','MFI','LSC') # APP和即時比分的宣傳單元不要算
group by userid, rp;

create table actionlog._rp_3 engine = myisam
select a.userid, sum(a.BRC) as BRC, sum(a.BZ) as BZ, sum(a.FRD) as FRD, sum(a.FRL) as FRL, sum(a.FRND) as FRND,
                 sum(a.HT) as HT, sum(a.IDX) as IDX, sum(a.MPB) as MPB, sum(a.US) as US, sum(a.WPB) as WPB
from (
    SELECT userid, (case when (rp='BRC') then c else 0 end) as BRC,
                   (case when (rp='BZ_') then c else 0 end) as BZ,
                   (case when (rp='FRD') then c else 0 end) as FRD,
                   (case when (rp='FRL') then c else 0 end) as FRL,
                   (case when (rp='FRN') then c else 0 end) as FRND,
                   (case when (rp='HT_') then c else 0 end) as HT,
                   (case when (rp='IDX') then c else 0 end) as IDX,
                   (case when (rp='MPB') then c else 0 end) as MPB,
                   (case when (rp='USE') then c else 0 end) as US,
                   (case when (rp='WPB') then c else 0 end) as WPB
    FROM actionlog._rp_2) as a
group by a.userid;

SELECT 'userid','BRC','BZ','FRD','FRL','FRND','HT','IDX','MPB','US','WPB' union (
SELECT *
into outfile 'C:/proc/dumps/_rp_3.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._rp_3);


# 處理page的部分
create table actionlog._pv_201505 engine = myisam
SELECT userid, uri, time, platform_type, substr(uri,2,locate('.php',uri)-2) as u FROM actionlog.action_201505 where userid <> '';
create table actionlog._pv_201506 engine = myisam
SELECT userid, uri, time, platform_type, substr(uri,2,locate('.php',uri)-2) as u FROM actionlog.action_201506 where userid <> '';
create table actionlog._pv_201507 engine = myisam
SELECT userid, uri, time, platform_type, substr(uri,2,locate('.php',uri)-2) as u FROM actionlog.action_201507 where userid <> '';

create table actionlog._pv_201505_1 engine = myisam
SELECT * FROM actionlog._pv_201505 where u in ('','index','forum','forumdetail','billboard','buy_predict','shopping_list','arrange_predict','visit_member','usersearch');
create table actionlog._pv_201506_1 engine = myisam
SELECT * FROM actionlog._pv_201506 where u in ('','index','forum','forumdetail','billboard','buy_predict','shopping_list','arrange_predict','visit_member','usersearch');
create table actionlog._pv_201507_1 engine = myisam
SELECT * FROM actionlog._pv_201507 where u in ('','index','forum','forumdetail','billboard','buy_predict','shopping_list','arrange_predict','visit_member','usersearch');

create table actionlog._pv_201505_2 engine = myisam
SELECT userid, uri, time, platform_type, (case when (u='') then 'index' else u end) as u, 
       (case when (locate('action=records',uri)>0) then 'record' else '' end) as a1,
       (case when (locate('action=friend',uri)>0) then 'friend' else '' end) as a2,
       (case when (locate('action=forum',uri)>0) then 'forum' else '' end) as a3,
       (case when (locate('ck=1',uri)>0) then 'ck_1' else '' end) as ck_1,
       (case when (locate('ck=2',uri)>0) then 'ck_2' else '' end) as ck_2,
       (case when (locate('killertype=medalfire',uri)>0) then 'k_mf' else '' end) as mf,
       (case when (locate('killertype=singlekiller',uri)>0) then 'k_sk' else '' end) as sk,
       (case when (locate('action=mainp',uri)>0) then 'mainp' else '' end) as rank,
       (case when (locate('&rp=HT',uri)>0) then 'head3' else '' end) as head3
FROM actionlog._pv_201505_1;

create table actionlog._pv_201506_2 engine = myisam
SELECT userid, uri, time, platform_type, (case when (u='') then 'index' else u end) as u, 
       (case when (locate('action=records',uri)>0) then 'record' else '' end) as a1,
       (case when (locate('action=friend',uri)>0) then 'friend' else '' end) as a2,
       (case when (locate('action=forum',uri)>0) then 'forum' else '' end) as a3,
       (case when (locate('ck=1',uri)>0) then 'ck_1' else '' end) as ck_1,
       (case when (locate('ck=2',uri)>0) then 'ck_2' else '' end) as ck_2,
       (case when (locate('killertype=medalfire',uri)>0) then 'k_mf' else '' end) as mf,
       (case when (locate('killertype=singlekiller',uri)>0) then 'k_sk' else '' end) as sk,
       (case when (locate('action=mainp',uri)>0) then 'mainp' else '' end) as rank,
       (case when (locate('&rp=HT',uri)>0) then 'head3' else '' end) as head3
FROM actionlog._pv_201506_1;

create table actionlog._pv_201507_2 engine = myisam
SELECT userid, uri, time, platform_type, (case when (u='') then 'index' else u end) as u, 
       (case when (locate('action=records',uri)>0) then 'record' else '' end) as a1,
       (case when (locate('action=friend',uri)>0) then 'friend' else '' end) as a2,
       (case when (locate('action=forum',uri)>0) then 'forum' else '' end) as a3,
       (case when (locate('ck=1',uri)>0) then 'ck_1' else '' end) as ck_1,
       (case when (locate('ck=2',uri)>0) then 'ck_2' else '' end) as ck_2,
       (case when (locate('killertype=medalfire',uri)>0) then 'k_mf' else '' end) as mf,
       (case when (locate('killertype=singlekiller',uri)>0) then 'k_sk' else '' end) as sk,
       (case when (locate('action=mainp',uri)>0) then 'mainp' else '' end) as rank,
       (case when (locate('&rp=HT',uri)>0) then 'head3' else '' end) as head3
FROM actionlog._pv_201507_1;

# note: 分別花了
# actionlog._pv_201505_2: 988 secs
# actionlog._pv_201506_2: 1171 sesc
# actionlog._pv_201507_2: 622 sesc

create table actionlog._pv engine = myisam
SELECT userid, uri, time, platform_type, concat(u,'_',a1,a2,a3,ck_1,ck_2,mf,sk,rank,head3) as u FROM actionlog._pv_201505_2;
insert ignore into actionlog._pv
SELECT userid, uri, time, platform_type, concat(u,'_',a1,a2,a3,ck_1,ck_2,mf,sk,rank,head3) as u FROM actionlog._pv_201506_2;
insert ignore into actionlog._pv
SELECT userid, uri, time, platform_type, concat(u,'_',a1,a2,a3,ck_1,ck_2,mf,sk,rank,head3) as u FROM actionlog._pv_201507_2;

        ALTER TABLE actionlog._pv CHANGE `u` `u` VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;       

create table actionlog._pv_1 engine = myisam
SELECT userid, uri, time, platform_type, 
       (case when (u='buy_predict_')         then 'buy_predict_k_mf'
             when (u='buy_predict_ck_1')     then 'buy_predict_k_mf'
             when (u='buy_predict_ck_2k_sk') then 'buy_predict_k_sk'
             when (u='forumdetail_ck_1')     then 'forumdetail_' else u end) as u
FROM actionlog._pv
where time between subdate(now(),90) and now();


# ---------------------
# 在這裡執行slice01.py
# ---------------------

create table actionlog._temp_all_1 engine = myisam
SELECT userid,  (case when (u='arrange_predict_')    then c else 0 end) as arrange_predict,
                (case when (u='billboard_')          then c else 0 end) as billboard,
                (case when (u='billboard_mainp')     then c else 0 end) as billboard_mainp,
                (case when (u='buy_predict_k_mf')    then c else 0 end) as buy_predict_k_mf,
                (case when (u='buy_predict_k_sk')    then c else 0 end) as buy_predict_k_sk,
                (case when (u='forumdetail_')        then c else 0 end) as forumdetail,
                (case when (u='forum_')              then c else 0 end) as forum,
                (case when (u='index_')              then c else 0 end) as idx,
                (case when (u='shopping_list_')      then c else 0 end) as shopping_list,
                (case when (u='usersearch_')         then c else 0 end) as usersearch,
                (case when (u='visit_member_')       then c else 0 end) as visit_member,
                (case when (u='visit_member_forum')  then c else 0 end) as visit_member_forum,
                (case when (u='visit_member_friend') then c else 0 end) as visit_member_friend,
                (case when (u='visit_member_head3')  then c else 0 end) as visit_member_head3,
                (case when (u='visit_member_record') then c else 0 end) as visit_member_record
FROM actionlog._temp_all;

create table actionlog._temp_all_2 engine = myisam
SELECT userid, sum(arrange_predict) as arrange_predict, sum(billboard) as billboard, sum(billboard_mainp) as billboard_mainp , 
               sum(buy_predict_k_mf) as buy_predict_k_mf , sum(buy_predict_k_sk) as buy_predict_k_sk , sum(forumdetail) as forumdetail , 
               sum(forum) as forum , sum(idx) as idx , sum(shopping_list) as shopping_list , sum(usersearch) as usersearch , 
               sum(visit_member) as visit_member , sum(visit_member_forum) as visit_member_forum , sum(visit_member_friend) as visit_member_friend , 
               sum(visit_member_head3) as visit_member_head3 , sum(visit_member_record) as visit_member_record
FROM actionlog._temp_all_1
group by userid;

create table actionlog._temp_all_3 engine = myisam
SELECT userid, arrange_predict, billboard, billboard_mainp, buy_predict_k_mf, buy_predict_k_sk, 
       forumdetail, shopping_list, usersearch, visit_member_forum, visit_member_friend, visit_member_head3, visit_member_record, idx
FROM actionlog._temp_all_2;


# 輸出.csv
SELECT 'userid','arrange_predict','billboard','billboard_mainp','buy_predict_k_mf','buy_predict_k_sk','forumdetail','shopping_list',
       'usersearch','visit_member_forum','visit_member_friend','visit_member_head3','visit_member_record','idx' union (
SELECT *
into outfile 'C:/proc/dumps/_temp_all_3.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._temp_all_3
where (arrange_predict+billboard+billboard_mainp+buy_predict_k_mf+buy_predict_k_sk+forumdetail+shopping_list+
       usersearch+visit_member_forum+visit_member_friend+visit_member_head3+visit_member_record+idx)>0);

# 執行slice02.py可以產出所有變數的percentile和.csv檔

create table actionlog._pcash_log engine = myisam
SELECT userid, sum(amount) as spent 
FROM plsport_playsport.pcash_log
where payed = 1 and type = 1
and date between subdate(now(),90) and now()
group by userid;

SELECT 'userid','spent' union (
SELECT *
into outfile 'C:/proc/dumps/_spent.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._pcash_log);



# =================================================================================================
# [201507-A-1]開發討論區會員追蹤功能-電訪名單撈取
# http://redmine.playsport.cc/issues/119
# 是由 郭 靜怡 於 3 天 前加入. 於 3 天 前更新.
# 說明 目的：提供電訪名單
# 內容 條件：
# 問卷第二題回答需要或非常需要
# 近一個月討論區pv前50% 
# 
# 欄位：
# 帳號、暱稱、討論區pv及全站佔比、手機/電腦使用比例、問卷第二題答案
# =================================================================================================

# 此名單和任務http://pm.playsport.cc/index.php/tasksComments?tasksId=4934&projectId=11差不多

# 撈近1個月內的資料
create table actionlog._forum_201506 engine = myisam
SELECT userid, uri, time, (case when (platform_type=2) then 'mobile' else 'pc' end) as p
FROM actionlog.action_201506 where userid <> '' and uri like '%/forum%'
and time between subdate(now(),31) and now();

create table actionlog._forum_201507 engine = myisam
SELECT userid, uri, time, (case when (platform_type=2) then 'mobile' else 'pc' end) as p
FROM actionlog.action_201507 where userid <> '' and uri like '%/forum%'
and time between subdate(now(),31) and now();

create table actionlog._forum engine = myisam select * from actionlog._forum_201506;
insert ignore into actionlog._forum select * from actionlog._forum_201507;

create table actionlog._forum_1 engine = myisam
SELECT * 
FROM actionlog._forum
where time between subdate(now(),31) and now();

create table actionlog._forum_2 engine = myisam
SELECT userid, p, count(p) as pv
FROM actionlog._forum_1
group by userid, p;

create table actionlog._forum_3 engine = myisam
select a.userid, sum(a.pc) as pc, sum(a.mobile) as mobile
from (
    SELECT userid, (case when (p='pc') then pv else 0 end) as pc,
                   (case when (p='mobile') then pv else 0 end) as mobile
    FROM actionlog._forum_2) as a
group by a.userid;

create table actionlog._forum_4 engine = myisam
SELECT userid, (pc+mobile) as pv, round((pc/(pc+mobile)),3) as pc_p, round((mobile/(pc+mobile)),3) as mobile_p
FROM actionlog._forum_3;

create table actionlog._forum_5 engine = myisam
select userid, pv, round((cnt-rank+1)/cnt,2) as pv_percentile, pc_p, mobile_p
from (SELECT userid, pv, @curRank := @curRank + 1 AS rank, pc_p, mobile_p
      FROM actionlog._forum_4, (SELECT @curRank := 0) r
      order by pv desc) as dt,
     (select count(distinct userid) as cnt from actionlog._forum_4) as ct;

        ALTER TABLE actionlog._forum_5 convert to character set utf8 collate utf8_general_ci;

create table actionlog._forum_6 engine = myisam
SELECT a.userid, b.nickname, a.pv, a.pv_percentile, a.pc_p, a.mobile_p
FROM actionlog._forum_5 a left join plsport_playsport.member b on a.userid = b.userid;

# http://www.playsport.cc/questionnaire.php?question=201506031444432350&action=statistics
# 是否需要討論區會員追蹤功能（說明：即時得知您喜愛的玩家有無發文、上線等狀態）

        create table plsport_playsport._qu engine = myisam
        SELECT userid,  `1433314771` as q
        FROM plsport_playsport.questionnaire_201506031444432350_answer
        where `1433314771` in (1,2);

create table actionlog._forum_7 engine = myisam
SELECT a.userid, a.nickname, a.pv, a.pv_percentile, a.pc_p, a.mobile_p, b.q
FROM actionlog._forum_6 a left join plsport_playsport._qu b on a.userid = b.userid
where b.q is not null
order by pv desc;

        # 最近一次的登入時間
        CREATE TABLE plsport_playsport._last_login_time engine = myisam
        SELECT userid, max(signin_time) as last_login
        FROM plsport_playsport.member_signin_log_archive
        GROUP BY userid;
        
        ALTER TABLE plsport_playsport._last_login_time convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._forum_7 convert to character set utf8 collate utf8_general_ci;
        ALTER TABLE actionlog._forum_7 ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._last_login_time ADD INDEX (`userid`);
        
create table actionlog._forum_8 engine = myisam
SELECT a.userid, a.nickname, a.pv, a.pv_percentile, a.pc_p, a.mobile_p, a.q, date(b.last_login) as last_login
from actionlog._forum_7 a left join plsport_playsport._last_login_time b on a.userid = b.userid
where a.pv_percentile>0.49;

        ALTER TABLE actionlog._forum_8 CHANGE `q` `q` VARCHAR(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL;
        update actionlog._forum_8 set q = '非常需要' where q = '1';
        update actionlog._forum_8 set q = '需要'     where q = '2';

SELECT '帳號', '暱稱', '討論區pv', '全站佔比', '電腦使用比例', '手機使用比例', '問卷第二題答案', '最後登入時間' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_forum_8.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._forum_8);



# =================================================================================================
# 購牌清單追蹤、購買後個人頁觀看情形 
# TO Eddy (學文) 2015-07-29
# http://redmine.playsport.cc/issues/80#
# 需要追蹤7/14  00:00 ~ 7/27  23:59 兩週期間以下的狀況
# 
# 美國職棒
# 
# 1.消費者購牌後，在比賽當日賽事打完後14:00~23:59，點選購牌清單的情況
# ex.如7/1購買7/2號美棒賽事，在7/2的14:00~23:59，這段期間點選購牌清單的狀況
# 
# 2.消費者購牌後，在比賽當日賽事打完後14:00~23:59，回到他購買的那位殺手的比賽當日預測頁的情況
# ex.如7/1購買A殺手7/2美棒的賽事，在7/2   14:00~23:59，回到A殺手7/2美棒的預測頁的情況
# =================================================================================================

create table plsport_playsport._buyer engine = myisam
SELECT buyerid, id_bought, buy_date, buy_price, allianceid 
FROM plsport_playsport._predict_buyer
where buy_date between subdate(now(),31) and now();

        ALTER TABLE plsport_playsport._buyer ADD INDEX (`id_bought`);
        ALTER TABLE plsport_playsport.predict_seller ADD INDEX (`id`);

create table plsport_playsport._buy_list_mlb engine = myisam
SELECT a.buyerid, a.buy_date, a.buy_price, a.allianceid, b.sellerid, b.sale_allianceid, b.sale_gameid, b.sale_date 
FROM plsport_playsport._buyer a left join plsport_playsport.predict_seller b on a.id_bought = b.id
where b.sale_allianceid = 2 /*換聯盟*/
and buy_date between '2015-07-14 00:00:00' and '2015-07-31 23:59:59';

create table plsport_playsport._buy_list_mlb_1 engine = myisam
SELECT buyerid, buy_date, buy_price, allianceid, sellerid, sale_allianceid, sale_gameid, sale_date,
       concat(substr(sale_gameid,1,4),'-', substr(sale_gameid,5,2),'-', substr(sale_gameid,7,2)) as game_date
FROM plsport_playsport._buy_list_mlb;

        # (a) 有區分跟那個殺手買, 之後要去查詢是否買的人會去看賣的人的頁面
        create table plsport_playsport._buy_list_mlb_2 engine = myisam
        SELECT buyerid, sellerid, sum(buy_price) as total_buy, game_date 
        FROM plsport_playsport._buy_list_mlb_1
        group by buyerid, sellerid, game_date;
 
        # (c) 沒有區分跟那個殺手買
        create table plsport_playsport._buy_list_mlb_3 engine = myisam        
        SELECT buyerid, sum(total_buy) as total_buy, game_date 
        FROM plsport_playsport._buy_list_mlb_2
        group by buyerid, game_date;

# [比較對象1:有去點購牌清單]
# 匯入event- 注意:不要去限制時間區間
create table plsport_playsport._click_purchase_history engine = myisam
SELECT userid, name, platform_type, time, date(time) as d 
FROM plsport_playsport.events
where name like '%purchase_history%'
and substr(time,12,2) in (21,22,23); # (14,15,16,17,18,19,20,21,22,23)

        # (b)
        create table plsport_playsport._click_purchase_history_1 engine = myisam
        SELECT userid, d, count(name) as click_count 
        FROM plsport_playsport._click_purchase_history
        where userid <> ''
        group by userid, d;
       
# [比較對象2:比賽完當天有去看殺手個人頁]    
create table plsport_playsport._click_killer_page_history engine = myisam
SELECT userid, uri, time 
FROM actionlog.action_201507
where userid <> ''
and time between '2015-07-14 00:00:00' and now()
and uri like '%visit_member%'
and substr(time,12,2) in (21,22,23); # (14,15,16,17,18,19,20,21,22,23)      
        
create table plsport_playsport._click_killer_page_history_1 engine = myisam   
SELECT * FROM plsport_playsport._click_killer_page_history
where uri not like '%ga=predict%'
and uri not like   '%action=records%'
and uri not like   '%action=forum%'
and uri not like   '%action=honor%'
and uri not like   '%action=friend%';

create table plsport_playsport._click_killer_page_history_2 engine = myisam    
SELECT userid, uri, time, substr(uri, locate('visit=',uri), length(uri)) as v, substr(uri, locate('allianceid=',uri), length(uri)) as a
FROM plsport_playsport._click_killer_page_history_1;  

create table plsport_playsport._click_killer_page_history_3 engine = myisam
select *
from (
    SELECT userid, uri, time, (case when (locate('&',v)>0) then substr(v,7,locate('&',v)-7) else substr(v,7,length(v)) end) as v,
                              (case when (locate('&',a)>0) then substr(a,12,locate('&',a)-12) else substr(a,12,length(a)) end) as a
    FROM plsport_playsport._click_killer_page_history_2) as a
where a.a in (2) /*換聯盟, 如果不是MLB要取消掉空白, 如果是MLB:(1, '')*/
and a.userid <> a.v;
       
create table plsport_playsport._click_killer_page_history_4 engine = myisam
select a.userid, a.v as visit, a.d, count(uri) as pv
from (
    SELECT userid, uri, time, v, a, date(time) as d
    FROM plsport_playsport._click_killer_page_history_3) as a
group by a.userid, a.v, a.d;

# (c) left join (b)
create table plsport_playsport._a_list_1 engine = myisam
SELECT a.buyerid, a.total_buy, a.game_date, b.click_count
FROM plsport_playsport._buy_list_mlb_3 a left join plsport_playsport._click_purchase_history_1 b 
on a.buyerid = b.userid and a.game_date = b.d
order by a.buyerid;

ALTER TABLE plsport_playsport._buy_list_mlb_2 convert to character set utf8 collate utf8_general_ci;
ALTER TABLE plsport_playsport._click_killer_page_history_4 convert to character set utf8 collate utf8_general_ci;
ALTER TABLE plsport_playsport._click_killer_page_history_4 CHANGE `visit` `visit` VARCHAR(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE plsport_playsport._buy_list_mlb_2 ADD INDEX (`buyerid`,`sellerid`,`game_date`);
ALTER TABLE plsport_playsport._click_killer_page_history_4 ADD INDEX (`userid`,`visit`,`d`);

create table plsport_playsport._b_list_1 engine = myisam
SELECT a.buyerid, a.sellerid, a.total_buy, a.game_date, b.pv
FROM plsport_playsport._buy_list_mlb_2 a left join plsport_playsport._click_killer_page_history_4 b 
on a.buyerid = b.userid and a.sellerid = b.visit and a.game_date = b.d;


# 多少人買
SELECT game_date, count(buyerid) as buyer 
FROM plsport_playsport._a_list_1
group by game_date;

# 隔天有沒有去點購牌清單
SELECT game_date, count(buyerid) as buyer 
FROM plsport_playsport._a_list_1
where click_count is not null
group by game_date;


# 多少人買
select a.game_date, count(a.buyerid) as buyer_count
from (
    SELECT buyerid, game_date, sum(pv) as pv 
    FROM plsport_playsport._b_list_1
    group by buyerid, game_date) as a
group by a.game_date;

# 隔天有沒有回殺手個人頁看人數
select a.game_date, count(a.buyerid) as buyer_count
from (
    SELECT buyerid, game_date, sum(pv) as pv 
    FROM plsport_playsport._b_list_1
    where pv is not null
    group by buyerid, game_date) as a
group by a.game_date;



# =================================================================================================
# 任務: [201504-A-3] 手機瀏覽時加大聯盟選單 - MVP測試名單 [新建] (阿達) 2015-07-31
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4948&projectId=11
# 說明
# 提供此任務MVP測試名單
# 
# 1. 預測賽事、預測比例、個人預測頁
# 條件：
#         1. 近一個月預測賽事、預測比例二個頁面分別佔全站前 50%
#         2. 手機使用佔比超過 60%
#          
#         欄位：
#         a. 帳號
#         b. 暱稱
#         c. 近一個月預測賽事、預測比例個別pv及全站佔比
#         d. 手機、電腦使用比例
#  
# 2. 找高手、即時比分、勝率/主推榜、個人預測頁
# 條件:
#         1. 近一個月找高手(莊家殺手/單場殺手)、即時比分二個頁面分別佔全站前 50%
#         2. 近一個月勝率榜或主推榜佔全站前 50%
#         3. 手機使用佔比超過60%
#          
#         欄位：
#         a. 帳號
#         b. 暱稱
#         c. 近一個月找高手(莊家殺手/單場殺手)、即時比分、勝率榜、主推榜個別pv及全站佔比
#         d. 手機、電腦使用比例
# =================================================================================================

create table actionlog._action engine = myisam
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201507
where userid <> ''
and time between subdate(now(),32) and now();

insert ignore into actionlog._action
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201508
where userid <> ''
and time between subdate(now(),32) and now();

# 小樣本資料用
# create table actionlog._action engine = myisam
# SELECT userid, uri, time, platform_type 
# FROM actionlog.action_201507
# where userid <> ''
# and time between subdate(now(),7) and now();

create table actionlog._action_1 engine = myisam
SELECT userid, uri, time, platform_type, substr(uri,2,locate('.php',uri)+2) as p
FROM actionlog._action;

create table actionlog._action_2 engine = myisam
SELECT * FROM actionlog._action_1
where p in ('predictgame.php','livescore.php','buy_predict.php','billboard.php','visit_member.php');

create table actionlog._action_3 engine = myisam
select a.userid, a.uri, a.time, a.platform_type, a.p, concat(a.p,'_',a.s1,a.s2,a.s3,a.s4,a.s5,a.s6) as s
from (
    SELECT userid, uri, time, platform_type, p, (case when (locate('action=scale',uri)>0) then 'scale' else '' end)             as s1,
                                                (case when (locate('killertype=singlekiller',uri)>0) then 'single' else '' end) as s2,
                                                (case when (locate('action=mainp',uri)>0) then 'mainp' else '' end)             as s3,
                                                (case when (locate('action=records',uri)>0) then 'records' else '' end)         as s4,
                                                (case when (locate('action=forum',uri)>0) then 'forum' else '' end)             as s5,
                                                (case when (locate('action=honor',uri)>0) then 'honor' else '' end)             as s6
    FROM actionlog._action_2) as a;

# billboard.php_	      27316
# billboard.php_mainp	  40169
# buy_predict.php_	      33738
# buy_predict.php_single  12227
# livescore.php_	      608615
# predictgame.php_	      180033
# predictgame.php_scale	  163331

create table actionlog._action_4 engine = myisam
SELECT userid, s, count(uri) as c
FROM actionlog._action_3
where s not in ('visit_member.php_records','visit_member.php_forum','visit_member.php_honor')
group by userid, s;

create table actionlog._action_5 engine = myisam
SELECT userid, (case when (s='predictgame.php_') then c else 0 end) as predict,
               (case when (s='predictgame.php_scale') then c else 0 end) as scale,
               (case when (s='buy_predict.php_') then c else 0 end) as buy_,
               (case when (s='buy_predict.php_single') then c else 0 end) as buy_sig,
               (case when (s='livescore.php_') then c else 0 end) as live,
               (case when (s='billboard.php_') then c else 0 end) as bill,
               (case when (s='billboard.php_mainp') then c else 0 end) as bill_mainp,
               (case when (s='visit_member.php_') then c else 0 end) as vm
FROM actionlog._action_4;

create table actionlog._action_6 engine = myisam
select a.userid, a.predict as pred, a.scale, (a.buy_+a.buy_sig) as buy, a.live, a.bill, a.bill_mainp as billm, a.vm
from (
    SELECT userid, sum(predict) as predict, sum(scale) as scale, sum(buy_) as buy_, sum(buy_sig) as buy_sig, 
                   sum(live) as live, sum(bill) as bill, sum(bill_mainp) as bill_mainp, sum(vm) as vm
    FROM actionlog._action_5
    group by userid) as a;

# 執行slice03.py

SELECT 'userid' union (
SELECT userid
into outfile 'C:/proc/dumps/main.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog._action_6);


        # 這段是計算用電腦和手機的比例
        create table actionlog._forum_2 engine = myisam
        SELECT userid, platform_type, count(platform_type) as pv
        FROM actionlog._action_2
        group by userid, platform_type;

        create table actionlog._forum_3 engine = myisam
        select a.userid, sum(a.pc) as pc, sum(a.mobile) as mobile, sum(a.tablet) as tablet
        from (
            SELECT userid, (case when (platform_type='1') then pv else 0 end) as pc,
                           (case when (platform_type='2') then pv else 0 end) as mobile,
                           (case when (platform_type='3') then pv else 0 end) as tablet
            FROM actionlog._forum_2) as a
        group by a.userid;

        create table actionlog._forum_4 engine = myisam
        SELECT userid, round(((pc+tablet)/(pc+mobile+tablet)),3) as pc_p, round((mobile/(pc+mobile+tablet)),3) as mobile_p
        FROM actionlog._forum_3;

        SELECT 'userid','pc_p','mobile_p' union (
        SELECT *
        into outfile 'C:/proc/dumps/devices.csv'
        fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
        FROM actionlog._forum_4);


# 所有的檔案全都放在C:\proc\dumps

# 以下是R script, 直接開rstudio跑就可以了

# rm(list=ls())  
# main<-read.table("C:/proc/dumps/main.csv",   header=T, sep=",", quote="\"", fileEncoding="UTF-8", colClasses=c("userid"="factor"))
# a01<-read.table("C:/proc/dumps/p_pred.csv",  header=T, sep=",", quote="\"", fileEncoding="UTF-8", colClasses=c("userid"="factor"))
# a02<-read.table("C:/proc/dumps/p_scale.csv", header=T, sep=",", quote="\"", fileEncoding="UTF-8", colClasses=c("userid"="factor"))
# a03<-read.table("C:/proc/dumps/p_buy.csv",   header=T, sep=",", quote="\"", fileEncoding="UTF-8", colClasses=c("userid"="factor"))
# a04<-read.table("C:/proc/dumps/p_live.csv",  header=T, sep=",", quote="\"", fileEncoding="UTF-8", colClasses=c("userid"="factor"))
# a05<-read.table("C:/proc/dumps/p_bill.csv",  header=T, sep=",", quote="\"", fileEncoding="UTF-8", colClasses=c("userid"="factor"))
# a06<-read.table("C:/proc/dumps/p_billm.csv", header=T, sep=",", quote="\"", fileEncoding="UTF-8", colClasses=c("userid"="factor"))
# a07<-read.table("C:/proc/dumps/p_vm.csv",    header=T, sep=",", quote="\"", fileEncoding="UTF-8", colClasses=c("userid"="factor"))
# a08<-read.table("C:/proc/dumps/devices.csv", header=T, sep=",", quote="\"", fileEncoding="UTF-8", colClasses=c("userid"="factor"))
# 
# m<-main[c(1)]
# m<-merge(x=m, y=a01, by='userid', all.x=TRUE)
# m<-merge(x=m, y=a02, by='userid', all.x=TRUE)
# m<-merge(x=m, y=a03, by='userid', all.x=TRUE)
# m<-merge(x=m, y=a04, by='userid', all.x=TRUE)
# m<-merge(x=m, y=a05, by='userid', all.x=TRUE)
# m<-merge(x=m, y=a06, by='userid', all.x=TRUE)
# m<-merge(x=m, y=a07, by='userid', all.x=TRUE)
# m<-merge(x=m, y=a08, by='userid', all.x=TRUE)
# m[is.na(m)]<-0
# 
# m$list1[m$pred_p>=0.5 & m$scale_p>=0.5 & m$mobile_p>=0.6]<-'1'
# m$list2[m$buy_p>=0.5 & m$live_p>=0.5 & (m$bill_p>=0.5 | m$billm_p>=0.5) & m$mobile_p>=0.6]<-'1'
# 
# m$list1<-as.factor(m$list1)
# m$list2<-as.factor(m$list2)
# 
# m1<-subset(m, (!is.na(m$list1) | !is.na(m$list2)))
# 
# names(m1)<-c('userid','預測賽事','預測賽事p','預測比例','預測比例p','找高手','找高手p','即時比分','即時比分p','勝率榜',
#              '勝率榜p','主推榜','主推榜p','個人預測頁','個人預測頁p','電腦比例','手機比例','名單1','名單2')
# 
# write.table(m1, file = "C:/proc/dumps/done.csv", append = FALSE, quote = TRUE, sep = ",",
#             eol = "\n", na = "NA", row.names = FALSE,
#             col.names = TRUE, fileEncoding = "UTF-8")
# rm(list=ls())

# 檔案完成後會放置 C:/proc/dumps/done.csv





# =================================================================================================
# 研究討論區流量下滑問題 2015-08-13 (阿達)
# 分析流量、回文數下滑原因
# http://redmine.playsport.cc/issues/193
# 
# 內容
# 1. 討論區流量下滑
# 於六月中開始，討論區流量持續下滑，至8/10已下滑約 30%
# 
# 2. 討論區回文數下滑
# 於七月底開始，討論區回文持續下滑，至8/10以下滑約 30%
# =================================================================================================

# create table actionlog._forumdetail_201306 engine = myisam SELECT userid, uri, time FROM actionlog.action_201306 where uri like '%forumdetail.php%';
# create table actionlog._forumdetail_201307 engine = myisam SELECT userid, uri, time FROM actionlog.action_201307 where uri like '%forumdetail.php%';
# create table actionlog._forumdetail_201308 engine = myisam SELECT userid, uri, time FROM actionlog.action_201308 where uri like '%forumdetail.php%';
create table actionlog._forumdetail_201406 engine = myisam SELECT userid, uri, time FROM actionlog.action_201406 where uri like '%forumdetail.php%';
create table actionlog._forumdetail_201407 engine = myisam SELECT userid, uri, time FROM actionlog.action_201407 where uri like '%forumdetail.php%';
create table actionlog._forumdetail_201408 engine = myisam SELECT userid, uri, time FROM actionlog.action_201408 where uri like '%forumdetail.php%';
create table actionlog._forumdetail_201506 engine = myisam SELECT userid, uri, time FROM actionlog.action_201506 where uri like '%forumdetail.php%';
create table actionlog._forumdetail_201507 engine = myisam SELECT userid, uri, time FROM actionlog.action_201507 where uri like '%forumdetail.php%';
create table actionlog._forumdetail_201508 engine = myisam SELECT userid, uri, time FROM actionlog.action_201508 where uri like '%forumdetail.php%';

create table actionlog.__forumdetail_201406 engine = myisam
select a.userid, a.time, (case when (locate('&',a.s)>0) then substr(a.s,1,locate('&',a.s)-1) else a.s end) as s
from (SELECT userid, uri, time, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._forumdetail_201406) as a;
create table actionlog.__forumdetail_201407 engine = myisam
select a.userid, a.time, (case when (locate('&',a.s)>0) then substr(a.s,1,locate('&',a.s)-1) else a.s end) as s
from (SELECT userid, uri, time, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._forumdetail_201407) as a;
create table actionlog.__forumdetail_201408 engine = myisam
select a.userid, a.time, (case when (locate('&',a.s)>0) then substr(a.s,1,locate('&',a.s)-1) else a.s end) as s
from (SELECT userid, uri, time, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._forumdetail_201408) as a;
create table actionlog.__forumdetail_201506 engine = myisam
select a.userid, a.time, (case when (locate('&',a.s)>0) then substr(a.s,1,locate('&',a.s)-1) else a.s end) as s
from (SELECT userid, uri, time, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._forumdetail_201506) as a;
create table actionlog.__forumdetail_201507 engine = myisam
select a.userid, a.time, (case when (locate('&',a.s)>0) then substr(a.s,1,locate('&',a.s)-1) else a.s end) as s
from (SELECT userid, uri, time, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._forumdetail_201507) as a;
create table actionlog.__forumdetail_201508 engine = myisam
select a.userid, a.time, (case when (locate('&',a.s)>0) then substr(a.s,1,locate('&',a.s)-1) else a.s end) as s
from (SELECT userid, uri, time, substr(uri,locate('subjectid=',uri)+10,length(uri)) as s FROM actionlog._forumdetail_201508) as a;

ALTER TABLE actionlog.__forumdetail_201406 CHANGE `s` `s` VARCHAR(40) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE actionlog.__forumdetail_201407 CHANGE `s` `s` VARCHAR(40) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE actionlog.__forumdetail_201408 CHANGE `s` `s` VARCHAR(40) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE actionlog.__forumdetail_201506 CHANGE `s` `s` VARCHAR(40) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE actionlog.__forumdetail_201507 CHANGE `s` `s` VARCHAR(40) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE actionlog.__forumdetail_201508 CHANGE `s` `s` VARCHAR(40) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

ALTER TABLE plsport_playsport.forum ADD INDEX (`subjectid`);

create table actionlog.__forumdetail engine = myisam select * from actionlog.__forumdetail_201406;
insert ignore into actionlog.__forumdetail select * from actionlog.__forumdetail_201407;
insert ignore into actionlog.__forumdetail select * from actionlog.__forumdetail_201408;
insert ignore into actionlog.__forumdetail select * from actionlog.__forumdetail_201506;
insert ignore into actionlog.__forumdetail select * from actionlog.__forumdetail_201507;
insert ignore into actionlog.__forumdetail select * from actionlog.__forumdetail_201508;

# 執行slide04.py
# 主要是將actionlog.__forumdetail 加上allianceid的資訊, 使用left join
# [Finished in 6327.7s]

rename table actionlog._temp to actionlog.__forumdetail_1;

create table actionlog.__forumdetail_2 engine = myisam
SELECT date(time) as d, s, allianceid FROM actionlog.__forumdetail_1;

# 執行slide05.py
# 主要是將actionlog.__forumdetail_2依日期和聯盟group起來
# [Finished in 2053.9s]

create table actionlog.__forumdetail_3 engine = myisam
SELECT d, allianceid, sum(pv) as pv 
FROM actionlog._temp
group by d, allianceid;

create table actionlog.__forumdetail_4 engine = myisam
SELECT a.d, a.allianceid, b.alliancename, a.pv 
FROM actionlog.__forumdetail_3 a left join  plsport_playsport.alliance b on a.allianceid = b.allianceid;

create table actionlog.__forumdetail_5 engine = myisam
SELECT d, substr(d,1,4) as y, substr(d,6,10) as da,  allianceid, alliancename, pv 
FROM actionlog.__forumdetail_4
where alliancename is not null;

create table actionlog.__forumdetail_6 engine = myisam
SELECT * FROM actionlog.__forumdetail_5
where da between '06-15' and '08-31';


create table plsport_playsport._forum engine = myisam
select a.allianceid, a.postuser, a.posttime, a.y, a.da, a.replycount
from (
    SELECT allianceid, postuser, posttime, substr(posttime,1,4) as y, substr(posttime,6,5) as da, replycount
    FROM plsport_playsport.forum) as a
where a.y in (2014,2015)
and a.da between '06-15' and '08-31';

create table plsport_playsport._forum_post engine = myisam
SELECT y, da, allianceid, count(postuser) as post_count 
FROM plsport_playsport._forum
group by y, da, allianceid;

create table plsport_playsport._forum_reply engine = myisam
SELECT y, da, allianceid, sum(replycount) as replycount 
FROM plsport_playsport._forum
group by y, da, allianceid;

create table plsport_playsport._forum_post1 engine = myisam
SELECT a.y, a.da, a.allianceid, b.alliancename, a.post_count 
FROM plsport_playsport._forum_post a left join plsport_playsport.alliance b on a.allianceid = b.allianceid;

create table plsport_playsport._forum_reply1 engine = myisam
SELECT a.y, a.da, a.allianceid, b.alliancename, a.replycount 
FROM plsport_playsport._forum_reply a left join plsport_playsport.alliance b on a.allianceid = b.allianceid;

SELECT 'd', 'y', 'da', 'allianceid', 'alliancename', 'pv' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/__forumdetail_6.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog.__forumdetail_6
where allianceid in (1,2,3,4,6,9));

SELECT 'y', 'da', 'allianceid', 'alliancename', 'post_count' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_forum_post.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._forum_post1
where allianceid in (1,2,3,4,6,9));

SELECT 'y', 'da', 'allianceid', 'alliancename','reply_count' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_forum_reply.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._forum_reply1
where allianceid in (1,2,3,4,6,9));

SELECT 'd', 'pv' union (
SELECT d, sum(pv) as pv
into outfile 'C:/Users/1-7_ASUS/Desktop/pv_by_day.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog.__forumdetail_6
where allianceid in (1,2,3,4,6,9)
group by d);



# =================================================================================================
# 任務: [201504-B-3] 購牌專區 - 手機瀏覽時，加大暱稱與版標 - MVP測試名單 [進行中]
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4962&projectId=11
# 提此任務MVP測試名單
# 時間：8/24
# 
# 1. MVP測試名單
# 條件：
# a. 近一個月手機觀看購牌專區pv達前50%
# 
# 欄位：
# a. 帳號
# b. 暱稱
# c. 近一個月手機觀看購牌專區pv及佔比
# d. 近一個月手機於購牌專區購買金額及佔比
# e. 手機、電腦使用比例
# =================================================================================================

create table actionlog._action_task engine = myisam
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201507
where userid  <> '' and uri like '%buy_predict.php%'
and time between subdate(now(),31) and now(); # 近一個月

insert ignore into actionlog._action_task
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201508
where userid  <> '' and uri like '%buy_predict.php%'
and time between subdate(now(),31) and now(); # 近一個月

create table actionlog._visit_buy_predict engine = myisam
SELECT userid, count(uri) as pv 
FROM actionlog._action_task
where platform_type = 2
group by userid;

# (1)
create table actionlog._visit_buy_predict1 engine = myisam
select userid, pv, round((cnt-rank+1)/cnt,2) as pv_percentile
from (SELECT userid, pv, @curRank := @curRank + 1 AS rank
      FROM actionlog._visit_buy_predict, (SELECT @curRank := 0) r
      order by pv desc) as dt,
     (select count(distinct userid) as cnt from actionlog._visit_buy_predict) as ct;


CREATE TABLE plsport_playsport._predict_buyer engine = myisam
SELECT a.id, a.buyerid, a.id_bought, a.buy_date , a.buy_price, b.position, b.cons, b.allianceid
FROM plsport_playsport.predict_buyer a LEFT JOIN plsport_playsport.predict_buyer_cons_split b on a.id = b.id_predict_buyer
WHERE a.buy_price <> 0
AND a.buy_date between subdate(now(),31) AND now();

ALTER TABLE plsport_playsport._predict_buyer ADD INDEX (`id_bought`);  

#再join predict_seller
CREATE TABLE plsport_playsport._predict_buyer_with_cons engine = myisam
SELECT c.id, c.buyerid, c.id_bought, d.sellerid ,c.buy_date , c.buy_price, c.position, c.cons, c.allianceid
FROM plsport_playsport._predict_buyer c LEFT JOIN plsport_playsport.predict_seller d on c.id_bought = d.id
ORDER BY buy_date DESC;

CREATE TABLE plsport_playsport._who_buy_at_buypredict engine = myisam
SELECT buyerid as userid, sum(buy_price) as spent 
FROM plsport_playsport._predict_buyer_with_cons
where substr(position,1,2) = 'BZ'
group by buyerid;

# (2)
create table plsport_playsport._who_buy_at_buypredict1 engine = myisam
select userid, spent, round((cnt-rank+1)/cnt,2) as spent_percentile
from (SELECT userid, spent, @curRank := @curRank + 1 AS rank
      FROM plsport_playsport._who_buy_at_buypredict, (SELECT @curRank := 0) r
      order by spent desc) as dt,
     (select count(distinct userid) as cnt from plsport_playsport._who_buy_at_buypredict) as ct;

update actionlog._action_task set platform_type=1 where platform_type=3;

create table actionlog._action_task1 engine = myisam
SELECT userid, platform_type, count(uri) as pv 
FROM actionlog._action_task
group by userid, platform_type;

# (3)
create table actionlog._action_task_devices engine = myisam
select b.userid, round((b.pc/(b.pc+b.mobile)),3) as p_pc, round((b.mobile/(b.pc+b.mobile)),3) as p_mobile
from (
    select a.userid, sum(a.pc) as pc, sum(a.mobile) as mobile
    from (
        SELECT userid, (case when (platform_type=1) then pv else 0 end) as pc, (case when (platform_type=2) then pv else 0 end) as mobile
        FROM actionlog._action_task1) as a
    group by a.userid) as b;


        ALTER TABLE actionlog._visit_buy_predict1 ADD INDEX (`userid`); 
        ALTER TABLE plsport_playsport._who_buy_at_buypredict1 ADD INDEX (`userid`); 
        ALTER TABLE actionlog._action_task_devices ADD INDEX (`userid`); 
        ALTER TABLE actionlog._visit_buy_predict1 CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE plsport_playsport._who_buy_at_buypredict1 CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE actionlog._action_task_devices CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

# To Eddy：
# 抱歉，請再幫我加上兩個欄位

        # g. 最近使用購牌專區日期
        create table plsport_playsport._who_visit_buypredict_lasttime engine = myisam
        SELECT userid, date(max(time)) as last_time_visit_buy
        FROM actionlog._action_task
        where platform_type = 2
        group by userid;

        # f. 最近登入日期
        CREATE TABLE plsport_playsport._last_time_login engine = myisam
        SELECT userid, date(max(signin_time)) as signin_time 
        FROM plsport_playsport.member_signin_log_archive
        GROUP BY userid;

        ALTER TABLE plsport_playsport._who_visit_buypredict_lasttime ADD INDEX (`userid`); 
        ALTER TABLE plsport_playsport._last_time_login ADD INDEX (`userid`); 
        ALTER TABLE plsport_playsport._who_visit_buypredict_lasttime CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
        ALTER TABLE plsport_playsport._last_time_login CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

create table plsport_playsport._mvp_list_1 engine = myisam
SELECT a.userid, b.nickname, a.pv, a.pv_percentile 
FROM actionlog._visit_buy_predict1 a left join plsport_playsport.member b on a.userid = b.userid;

create table plsport_playsport._mvp_list_2 engine = myisam
SELECT a.userid, a.nickname, a.pv, a.pv_percentile, b.spent, b.spent_percentile
FROM plsport_playsport._mvp_list_1 a left join plsport_playsport._who_buy_at_buypredict1 b on a.userid = b.userid;

create table plsport_playsport._mvp_list_3 engine = myisam
SELECT a.userid, a.nickname, a.pv, a.pv_percentile, a.spent, a.spent_percentile, b.p_pc, b.p_mobile
FROM plsport_playsport._mvp_list_2 a left join actionlog._action_task_devices b on a.userid = b.userid
where a.pv_percentile > 0.49;

create table plsport_playsport._mvp_list_4 engine = myisam
SELECT a.userid, a.nickname, a.pv, a.pv_percentile, a.spent, a.spent_percentile, a.p_pc, a.p_mobile, b.last_time_visit_buy
FROM plsport_playsport._mvp_list_3 a left join plsport_playsport._who_visit_buypredict_lasttime b on a.userid = b.userid;

create table plsport_playsport._mvp_list_5 engine = myisam
SELECT a.userid, a.nickname, a.pv, a.pv_percentile, a.spent, a.spent_percentile, a.p_pc, a.p_mobile, a.last_time_visit_buy, b.signin_time
FROM plsport_playsport._mvp_list_4 a left join plsport_playsport._last_time_login b on a.userid = b.userid;

SELECT 'userid', '暱稱', '購牌專區pv', '級距', '購牌專區購買金額', '級距', '電腦使用比例', '手機使用比例', '最近使用購牌專區', '最近登入'  union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_mvp_list_5.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._mvp_list_5);



# =================================================================================================
# 任務: [201504-C-6]即時比分頁新增宣傳單元-廣告內容點擊狀況工程設定 [已確認]
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4942&projectId=11
# 說明
# 目的：了解使用者喜愛那種宣傳單元廣告
# 
# 內容
# 設定追蹤代碼，EX：
# 有殺手無文章：LV_15(位置)_K(殺手)_K1F0
# 有殺手有文章：LV_15(位置)_F(文章)_K1F1
# 
# 任務: [201504-C-6]即時比分頁新增宣傳單元-廣告內容點擊狀況 [新建]
# 目的：了解使用者喜愛那種宣傳廣告
# 內容
# - 測試時間：7/23~8/23
# - 觀察指標：文章內容與殺手資訊點擊狀況
# - 報告時間：8/26
# =================================================================================================

create table actionlog._livescore engine = myisam 
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201507
where time between '2015-07-23 17:26:00' and now()
and uri like '%rp=LSC%';

insert ignore into actionlog._livescore
SELECT userid, uri, time, platform_type 
FROM actionlog.action_201508
where time between '2015-07-23 17:26:00' and now()
and uri like '%rp=LSC%';

create table actionlog._livescore1 engine = myisam 
SELECT userid, uri, time, platform_type as p, (case when (locate('K1F1',uri)>0) then substr(uri, locate('K1F1',uri)-9, 13) end) as u1,
                                              (case when (locate('K1F0',uri)>0) then substr(uri, locate('K1F0',uri)-9, 13) end) as u2
FROM actionlog._livescore;

update actionlog._livescore1 set u1='' where u1 is null;
update actionlog._livescore1 set u2='' where u2 is null;

create table actionlog._livescore2 engine = myisam 
SELECT userid, uri, time, p, trim(concat(u1,u2)) as u
FROM actionlog._livescore1;

create table actionlog._livescore3 engine = myisam 
SELECT * FROM actionlog._livescore2
where u <> '';

create table actionlog._livescore4 engine = myisam 
SELECT userid, uri, time, p, u, substr(u,5,2) as u1, substr(u,8,1) as u2, substr(u,10,4) as u3
FROM actionlog._livescore3;

create table actionlog._livescore5 engine = myisam
SELECT u3, u2, u1, count(uri) as c 
FROM actionlog._livescore4
group by u3, u2, u1;




# =================================================================================================
# 任務: [201412-F-20] 即時比分顯示隔日賽事數據 - 分析問卷結果 [進行中]
# http://pm.playsport.cc/index.php/tasksComments?tasksId=4966&projectId=11
#  
# 分析"即時比分賽事數據"問卷結果
# 負責人：Eddy
#  
# 時間：9/21(五)
# 問券id為201509081556429556
# =================================================================================================

# 先匯入questionnaire_201509081556429556_answer

create table plsport_playsport._temp_question engine = myisam
select * 
from plsport_playsport.questionnaire_201509081556429556_answer;


ALTER TABLE plsport_playsport.questionnaire_201509081556429556_answer CHANGE `1441698919` ans varchar(1000);

create table plsport_playsport._question engine = myisam
select userid, replace(ans, ' ', '') as ans
from plsport_playsport.questionnaire_201509081556429556_answer;

update plsport_playsport._question set ans = replace(ans, '.',''); 
update plsport_playsport._question set ans = replace(ans, ',',''); 
update plsport_playsport._question set ans = replace(ans, ';','');
update plsport_playsport._question set ans = replace(ans, '/','');
update plsport_playsport._question set ans = replace(ans, '\\','_');
update plsport_playsport._question set ans = replace(ans, '"','');
update plsport_playsport._question set ans = replace(ans, '&','');
update plsport_playsport._question set ans = replace(ans, '#','');
update plsport_playsport._question set ans = replace(ans, ' ','');
update plsport_playsport._question set ans = replace(ans, '\n','');
update plsport_playsport._question set ans = replace(ans, '\b','');
update plsport_playsport._question set ans = replace(ans, '\t','');
update plsport_playsport._question set ans = replace(ans, '\r','');
update plsport_playsport._question set ans = replace(ans, '謝謝','');
update plsport_playsport._question set ans = replace(ans, '~','');


create table plsport_playsport._question_1 engine = myisam
SELECT userid, ans
FROM plsport_playsport._question
where ans <> ''
and ans not in ('沒有','無','很棒','no','沒','ok','不用');

# 填寫: 1703
# 排除沒意見者: 727

create table plsport_playsport._question_2 engine = myisam
SELECT userid, ans
FROM plsport_playsport._question_1
where ans not like '%夠了%'
and ans not like '%很好%'
and ans not like '%沒意見%'
and ans not like '%無意見%'
and ans not like '%很棒了%'
and ans not like '%不需要%'
and ans not like '%很完美%'
and ans not like '%已足夠%'
and ans not like '%不用了%'
and ans not like '%NA%'
;

ALTER TABLE plsport_playsport._question_2 convert to character set utf8 collate utf8_general_ci;
ALTER TABLE plsport_playsport._question_2 CHANGE `ans` `ans` TEXT CHARACTER SET big5 COLLATE big5_chinese_ci NULL DEFAULT NULL;

SELECT 'userid', 'ans' union (
SELECT *
into outfile 'C:/proc/dumps/_question.csv'
fields terminated by ', ' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._question_2);








