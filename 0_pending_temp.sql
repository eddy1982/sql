# 2015-01-29 
# 用google map反查使用者位置, 需使用python

CREATE TABLE plsport_playsport._user_location engine = myisam 
SELECT * FROM plsport_playsport.app_action_log
WHERE app = 1 AND os = 1 # app=1即時比分, os=1是ANDriod 
AND appversion in ('2.3.2') AND latitude is not null;

CREATE TABLE plsport_playsport._user_location_1 engine = myisam 
SELECT a.deviceid, a.ip, a.latitude, a.longitude
FROM (
    SELECT deviceid, ip, latitude, longitude, max(datetime) as datetime, count(deviceid) as c
    FROM plsport_playsport._user_location
    GROUP BY deviceid, ip) as a
limit 0, 50;

# 單純輸出csv檔, 準備批次處理反向地理查
SELECT 'deviceid', 'ip', 'latitude', 'longitude' UNION (
SELECT *
INTO outfile 'C:/Users/1-7_ASUS/Desktop/user_location_1.csv'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._user_location_1);

CREATE TABLE plsport_playsport._location engine = myisam
SELECT id, deviceid, longitude, latitude, ip 
FROM plsport_playsport.app_action_log
WHERE longitude is not null
ORDER BY id DESC;

CREATE TABLE plsport_playsport._location_1 engine = myisam
SELECT ip, longitude, latitude, max(id), count(id)
FROM plsport_playsport._location
GROUP BY ip;




# 新的居住地對應表
create table plsport_playsport._user_living_city engine = myisam
SELECT userid, (case when (city=0) then '基隆'
                     when (city=1) then '台北市'
                     when (city=2) then '新北市' 
                     when (city=3) then '桃園' 
                     when (city=4) then '新竹'
                     when (city=6) then '苗栗'
                     when (city=7) then '台中'
                     when (city=9) then '彰化'
                     when (city=10) then '南投'
                     when (city=11) then '嘉義'
                     when (city=13) then '雲林'
                     when (city=14) then '台南'
                     when (city=16) then '高雄'
                     when (city=18) then '屏東'
                     when (city=19) then '宜蘭'
                     when (city=20) then '花蓮'
                     when (city=21) then '台東'
                     when (city=25) then '外島'
                     when (city=26) then '海外' else 'error' end)  as city
FROM plsport_playsport.user_living_city
where action = 1
group by userid, city;

create table plsport_playsport._udata engine = myisam
SELECT userid, (case when (city=0) then '基隆'
                     when (city=1) then '台北市'
                     when (city=2) then '新北市'
                     when (city=3) then '桃園'
                     when (city=4) then '新竹'
                     when (city=5) then '新竹'
                     when (city=6) then '苗栗'
                     when (city=7) then '台中'
                     when (city=8) then '台中'
                     when (city=9) then '彰化'
                     when (city=10) then '南投'
                     when (city=11) then '嘉義'
                     when (city=12) then '嘉義'
                     when (city=13) then '雲林'
                     when (city=14) then '台南'
                     when (city=15) then '台南'
                     when (city=16) then '高雄'
                     when (city=17) then '高雄'
                     when (city=18) then '屏東'
                     when (city=19) then '宜蘭'
                     when (city=20) then '花蓮'
                     when (city=21) then '台東'
                     when (city=22) then '外島'
                     when (city=23) then '外島'
                     when (city=24) then '外島'
                     when (city=25) then '外島' else 'error' end) as city
FROM plsport_playsport.udata
where length(address) > 1;

create table plsport_playsport._exchange_validate engine = myisam
SELECT userid, (case when (city=0) then '基隆'
                     when (city=1) then '台北市'
                     when (city=2) then '新北市'
                     when (city=3) then '桃園'
                     when (city=4) then '新竹'
                     when (city=5) then '新竹'
                     when (city=6) then '苗栗'
                     when (city=7) then '台中'
                     when (city=8) then '台中'
                     when (city=9) then '彰化'
                     when (city=10) then '南投'
                     when (city=11) then '嘉義'
                     when (city=12) then '嘉義'
                     when (city=13) then '雲林'
                     when (city=14) then '台南'
                     when (city=15) then '台南'
                     when (city=16) then '高雄'
                     when (city=17) then '高雄'
                     when (city=18) then '屏東'
                     when (city=19) then '宜蘭'
                     when (city=20) then '花蓮'
                     when (city=21) then '台東'
                     when (city=22) then '外島'
                     when (city=23) then '外島'
                     when (city=24) then '外島'
                     when (city=25) then '外島' else 'error' end) as city
FROM plsport_playsport.exchange_validate
where address is not null;

        ALTER TABLE plsport_playsport._user_living_city ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._udata ADD INDEX (`userid`);
        ALTER TABLE plsport_playsport._exchange_validate ADD INDEX (`userid`);

create table plsport_playsport._user_city_1 engine = myisam
select e.id, e.userid, e.city1, e.city2, f.city as city3
from (
    select c.id, c.userid, c.city1, d.city as city2
    from (
        SELECT a.id, a.userid, b.city as city1
        FROM plsport_playsport.member a left join plsport_playsport._udata b on a.userid =  b.userid) as c
        left join plsport_playsport._user_living_city as d on c.userid = d.userid) as e
        left join plsport_playsport._exchange_validate as f on e.userid = f.userid
where e.city1 is not null or e.city2 is not null or f.city is not null;

create table plsport_playsport._user_city_2 engine = myisam
select a.id, a.userid, a.city1, a.city2, a.city3, (case when (a.city1 is null) then a.city4 else a.city1 end) as city5
from (
    SELECT id, userid, city1, city2, city3, (case when (city2 is null) then city3 else city2 end) as city4 
    FROM plsport_playsport._user_city_1) as a;

create table plsport_playsport._user_city_3 engine = myisam
SELECT userid, city5 as city 
FROM plsport_playsport._user_city_2;

drop table plsport_playsport._user_living_city;
drop table plsport_playsport._udata;
drop table plsport_playsport._exchange_validate;
drop table plsport_playsport._user_city_1;
drop table plsport_playsport._user_city_2;
rename table plsport_playsport._user_city_3 to plsport_playsport._user_city;


select a.h, sum(a.price)
from (
    SELECT substr(createon,1,13) as h, price
    FROM plsport_playsport.order_data
    where create_from = 8
    and date(createon) between '2015-04-01' and '2015-04-05'
    and sellconfirm = 1) as a
group by a.h;


create table revenue._pcash_log_with_detailed_info engine = myisam
select c.userid, c.amount, c.c_date, c.c_month, c.c_year, c.ym,
      c.id, c.sellerid, c.sale_allianceid, d.alliancename, c.sale_date, c.sale_price, c.killtype, c.killmedal
from (
   SELECT a.userid, a.amount, a.c_date, a.c_month, a.c_year, a.ym, 
          b.id, b.sellerid, b.sale_allianceid, b.sale_date, b.sale_price, b.killtype, b.killmedal
   FROM revenue._pcash_log a left join revenue._predict_seller_with_medal b on a.id_this_type = b.id) as c
left join revenue._alliance as d on c.sale_allianceid = d.allianceid;






# 新增table
DROP TABLE IF EXISTS `actionlog`.`app_action_log`;

CREATE TABLE `actionlog`.`app_action_log` 
( `abtestGroup` VARCHAR(10) NOT NULL , 
  `remark`      VARCHAR(60) NOT NULL , 
  `deviceModel` VARCHAR(60) NOT NULL , 
  `ip`          VARCHAR(20) NOT NULL , 
  `app`         VARCHAR(10) NOT NULL , 
  `userid`      VARCHAR(30) NOT NULL , 
  `appVersion`  VARCHAR(15) NOT NULL , 
  `datetime`    VARCHAR(30) NOT NULL , 
  `deviceid`    VARCHAR(30) NOT NULL , 
  `deviceOsVersion` VARCHAR(30) NOT NULL , 
  `action`      VARCHAR(30) NOT NULL , 
  `os`          VARCHAR(10) NOT NULL
) ENGINE = MyISAM CHARACTER SET utf8 COLLATE utf8_general_ci;

TRUNCATE TABLE `actionlog`.`app_action_log`;

LOAD DATA LOCAL INFILE 'D:/mongo/data/app_action_log_201506.csv'
INTO TABLE `actionlog`.`app_action_log`
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

create table actionlog.app_action_log1 engine = myisam
SELECT abtestGroup, remark, deviceModel, ip, app, userid, appVersion, 
       (STR_TO_DATE(concat(substr(datetime,1,10),' ',substr(datetime,12,8)), '%Y-%m-%d %h:%i:%s') + interval 8 hour) as datetime, 
       deviceid, deviceOsVersion, action, os 
FROM actionlog.app_action_log
order by datetime desc;

DROP TABLE IF EXISTS `actionlog`.`app_action_log`;
RENAME TABLE `actionlog`.`app_action_log1` to `actionlog`.`app_action_log`;








# 幫社群捉分身 2015-02-15
# 
CREATE TABLE actionlog._cheat engine = myisam
SELECT * FROM actionlog.action_201502
WHERE userid in ('aaaa1234','k7777');

# 1. 比對user_agent
SELECT userid, user_agent, count(userid) as c 
FROM actionlog._cheat
GROUP BY  userid, user_agent;

# 2. 比對時間
SELECT a.userid, a.t, count(a.userid) as c
FROM (
    SELECT userid, substr(time,1,13) as t 
    FROM actionlog._cheat) as a
GROUP BY a.userid, a.t;

# 3. 比對造訪頁面
SELECT a.userid, a.uri, count(a.userid) as c
FROM (
    SELECT userid, substr(uri,1,locate('.php',uri)-1) as uri
    FROM actionlog._cheat) as a
GROUP BY a.userid, a.uri;

# http://redmine.playsport.cc/issues/63#change-170
# 開始日期:	2015-07-10 黃 雅雅
# TO eddy:
# 麻煩協助抓看看這兩個帳號，是否為分身。
# 
# 覺得是分身的原因:
# 同電腦、IP，有一次同IP前後登入狀況，預測相似，彼此都有看個人頁的紀錄，只是惹人愛較多
# 
# 惹人愛:q1212
# 邱文彬:xyz0705
# 
# 惹人愛聯絡不到，邱文彬的說法如下:
# :平常在家用電腦、在外面會借朋友的手機，玩國際盤不去運彩店，說身邊有一位姓吳的朋友，也是這位朋友帶他來我們網站的
# ，但平常不會互相討論預測，只有偶爾見面時聊聊網站最近誰比較準、賣很多人這樣，對自己的操作滿清楚的，平常會看球賽觀
# 察投手強弱，作為抓牌的依據。

create table actionlog._user engine = myisam
SELECT userid, uri, time, cookie_stamp, user_agent, platform_version FROM actionlog.action_201504 where userid in ('q1212','xyz0705');
insert ignore into actionlog._user
SELECT userid, uri, time, cookie_stamp, user_agent, platform_version FROM actionlog.action_201505 where userid in ('q1212','xyz0705');
insert ignore into actionlog._user
SELECT userid, uri, time, cookie_stamp, user_agent, platform_version FROM actionlog.action_201506 where userid in ('q1212','xyz0705');
insert ignore into actionlog._user
SELECT userid, uri, time, cookie_stamp, user_agent, platform_version FROM actionlog.action_201507 where userid in ('q1212','xyz0705');


SELECT userid, user_agent, count(uri) 
FROM actionlog._user
group by userid, user_agent
order by time desc;

SELECT userid, user_agent, count(uri) 
FROM actionlog._user
where user_agent = 'Mozilla/5.0 (Linux; U; Android 4.1.2; zh-tw; HTC_709d Build/JZO54K) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30'
group by userid, user_agent
order by time desc;

select a.userid, a.d, count(a.d)
from (
    SELECT userid, date(time) as d 
    FROM actionlog._user
    where user_agent = 'Mozilla/5.0 (Linux; U; Android 4.1.2; zh-tw; HTC_709d Build/JZO54K) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30') as a
group by a.userid, a.d
order by a.d;

# 依時間排序
SELECT a.userid, a.t, count(a.userid) as c
FROM (
    SELECT userid, substr(time,1,13) as t 
    FROM actionlog._user) as a
GROUP BY a.userid, a.t
order by a.t desc;


# 比對造訪頁面
SELECT a.userid, a.uri, count(a.userid) as c
FROM (
    SELECT userid, substr(uri,1,locate('.php',uri)-1) as uri
    FROM actionlog._user) as a
GROUP BY a.userid, a.uri;




CREATE TABLE `plsport_playsport`.`allwords` 
( `all_words` VARCHAR(30) NOT NULL , 
  `freq`      VARCHAR(10) NOT NULL 
) ENGINE = MyISAM CHARACTER SET utf8 COLLATE utf8_general_ci;


LOAD DATA INFILE 'C:/proc/dumps/all_words.csv' 
INTO TABLE `plsport_playsport`.`allwords`  
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;




create table plsport_playsport._people_not_in_member_browses engine = myisam
SELECT a.userid, a.nickname, b.browses
FROM plsport_playsport.member a left join plsport_playsport.member_browses b on a.userid = b.userid
where b.browses is null;


        ALTER TABLE plsport_playsport._people_not_in_member_browses ADD INDEX (`userid`);

create table actionlog._temp1 engine = myisam SELECT userid, uri, time, user_agent, platform_type FROM actionlog.action_201507 limit 0 , 10000000;
create table actionlog._temp2 engine = myisam SELECT userid, uri, time, user_agent, platform_type FROM actionlog.action_201507 limit 10000000 , 10000000;
create table actionlog._temp3 engine = myisam SELECT userid, uri, time, user_agent, platform_type FROM actionlog.action_201507 limit 20000000 , 10000000;
create table actionlog._temp4 engine = myisam SELECT userid, uri, time, user_agent, platform_type FROM actionlog.action_201507 limit 30000000 , 10000000;
create table actionlog._temp5 engine = myisam SELECT userid, uri, time, user_agent, platform_type FROM actionlog.action_201507 limit 40000000 , 10000000;
create table actionlog._temp6 engine = myisam SELECT userid, uri, time, user_agent, platform_type FROM actionlog.action_201507 limit 50000000 , 10000000;
create table actionlog._temp7 engine = myisam SELECT userid, uri, time, user_agent, platform_type FROM actionlog.action_201507 limit 60000000 , 10000000;
create table actionlog._temp8 engine = myisam SELECT userid, uri, time, user_agent, platform_type FROM actionlog.action_201507 limit 70000000 , 10000000;

ALTER TABLE actionlog._temp1 convert to character set utf8 collate utf8_general_ci;
ALTER TABLE actionlog._temp2 convert to character set utf8 collate utf8_general_ci;
ALTER TABLE actionlog._temp3 convert to character set utf8 collate utf8_general_ci;
ALTER TABLE actionlog._temp4 convert to character set utf8 collate utf8_general_ci;
ALTER TABLE actionlog._temp5 convert to character set utf8 collate utf8_general_ci;
ALTER TABLE actionlog._temp6 convert to character set utf8 collate utf8_general_ci;
ALTER TABLE actionlog._temp7 convert to character set utf8 collate utf8_general_ci;
ALTER TABLE actionlog._temp8 convert to character set utf8 collate utf8_general_ci;

create table plsport_playsport._people_not_in_member_browses_temp1 engine = myisam
SELECT a.userid, a.uri, a.time, a.user_agent, a.platform_type 
FROM actionlog._temp1 a inner join plsport_playsport._people_not_in_member_browses b on a.userid = b.userid;

create table plsport_playsport._people_not_in_member_browses_temp2 engine = myisam
SELECT a.userid, a.uri, a.time, a.user_agent, a.platform_type 
FROM actionlog._temp2 a inner join plsport_playsport._people_not_in_member_browses b on a.userid = b.userid;

create table plsport_playsport._people_not_in_member_browses_temp3 engine = myisam
SELECT a.userid, a.uri, a.time, a.user_agent, a.platform_type 
FROM actionlog._temp3 a inner join plsport_playsport._people_not_in_member_browses b on a.userid = b.userid;


create table plsport_playsport._people_not_in_member_browses_for_check1 engine = myisam
SELECT a.userid, a.nickname, a.browses, b.browses as browses2, a.createon
FROM plsport_playsport.member a left join plsport_playsport.member_browses b on a.userid = b.userid
where b.browses is null;







# 幫社群捉分身 2015-11-05
CREATE TABLE actionlog._cheat engine = myisam
SELECT * FROM actionlog.action_201508
WHERE userid in ('xyz0705','1583');
insert ignore into actionlog._cheat
SELECT * FROM actionlog.action_201509
WHERE userid in ('xyz0705','1583');
insert ignore into actionlog._cheat
SELECT * FROM actionlog.action_201510
WHERE userid in ('xyz0705','1583');
insert ignore into actionlog._cheat
SELECT * FROM actionlog.action_201511
WHERE userid in ('xyz0705','1583');


# 1. 比對user_agent
SELECT userid, user_agent, count(userid) as c 
FROM actionlog._cheat
GROUP BY  userid, user_agent;

# 2. 比對時間
SELECT a.userid, a.t, count(a.userid) as c
FROM (
    SELECT userid, substr(time,1,13) as t 
    FROM actionlog._cheat) as a
GROUP BY a.userid, a.t;

# 3. 比對造訪頁面
SELECT a.userid, a.uri, count(a.userid) as c
FROM (
    SELECT userid, substr(uri,1,locate('.php',uri)-1) as uri
    FROM actionlog._cheat) as a
GROUP BY a.userid, a.uri;