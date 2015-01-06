-- ======================================================================================  
-- 	Update: 2014/1/9
-- 	捉出註冊的一些機器人, 可以直接跑全部sql
-- 	只需要member

-- 	註冊機器人1
-- 		1. 0開頭
-- 		2. 4,5或6,7碼
-- 		3. 密碼都一樣
-- ======================================================================================

use plsport_playsport;
create table plsport_playsport._problem_members_1 engine = myisam
SELECT * FROM plsport_playsport.member
where passwd = '481b8e7a06b7956ba02bd70527ef4cc0'          /*條件1*/
and substr(userid,1,1) = '0'                               /*條件2*/
and char_length(userid) in (4,5,6,7)                       /*條件3*/
and date(createon) between '2013-01-01' and '2018-12-31'   /*2013~2018*/
order by id desc;

/*註冊機器人2*/
create table plsport_playsport._problem_members_2 engine = myisam
SELECT * FROM plsport_playsport.member
where userid like '%@%' and userid not like '%@yahoo.com.tw%' /*條件1*/
and browses <15                                               /*條件2*/
and date(createon) between '2013-01-01' and '2018-12-31'      /*2013~2018*/
order by nickname desc;

/*活死人walking dead*/
create table plsport_playsport._problem_members_3 engine = myisam
SELECT * FROM plsport_playsport.member
where browses <3
and date(createon) between '2013-01-01' and '2018-12-31';

/*新手買牌路徑的測試帳號*/
create table plsport_playsport._problem_members_4 engine = myisam
SELECT * FROM plsport_playsport.member
where substr(nickname,1,3) in ('一路發','發大財','賺大錢') # 撈出此3個名字
and substr(nickname,4,1) REGEXP '^-?[0-9]+$'               # 第4個字要為數字
and createon between '2014-01-01 00:00:00' and '2014-03-17 17:00:00';

/*註冊機器人3*/
create table plsport_playsport._problem_members_5 engine = myisam
SELECT * FROM plsport_playsport.member
where createon between '2013-11-01 00:00:00' and '2018-03-31 23:59:59'
and userid like '%@%'
order by createon desc;

/*貼文機器人*/
create table plsport_playsport._problem_members_6 engine = myisam
SELECT * FROM plsport_playsport.member
where userid like '%xiaojita%';

/*註冊機器人1 + 註冊機器人2 + 活死人 + 新手買牌路徑的測試帳號*/
insert ignore into plsport_playsport._problem_members_1 select * from plsport_playsport._problem_members_2;
insert ignore into plsport_playsport._problem_members_1 select * from plsport_playsport._problem_members_3;
insert ignore into plsport_playsport._problem_members_1 select * from plsport_playsport._problem_members_4;
insert ignore into plsport_playsport._problem_members_1 select * from plsport_playsport._problem_members_5;
insert ignore into plsport_playsport._problem_members_1 select * from plsport_playsport._problem_members_6;

drop table plsport_playsport._problem_members_2, plsport_playsport._problem_members_3, 
           plsport_playsport._problem_members_4, plsport_playsport._problem_members_5,
           plsport_playsport._problem_members_6;

/*完成:需要被排除掉的名單*/
create table plsport_playsport._problem_members engine = myisam
SELECT id, userid, count(id) as id_count 
FROM plsport_playsport._problem_members_1
group by id;

drop table plsport_playsport._problem_members_1;
ALTER TABLE plsport_playsport._problem_members ADD INDEX (`userid`);