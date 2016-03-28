
# 計算人數的執行順序 2016-3-28
# 1. 先執行8_user_find_the_rebot_register.sql
# 2. 再執行slice07.action_log.py, 記得改掉月份
# 3. 最後執行slice07_action_log_insert_each_month.py, 記得新增月份

# ======================================================================================  
#  Update: 2014/1/9
#  捉出註冊的一些機器人, 可以直接跑全部sql
#  只需要member 註冊機器人1
#      1. 0開頭
#      2. 4,5或6,7碼
#      3. 密碼都一樣
# ======================================================================================

use plsport_playsport;
drop table if exists plsport_playsport._problem_members_1;
create table plsport_playsport._problem_members_1 engine = myisam
SELECT userid FROM plsport_playsport.member
where passwd = '481b8e7a06b7956ba02bd70527ef4cc0'          /*條件1*/
and substr(userid,1,1) = '0'                               /*條件2*/
and char_length(userid) in (4,5,6,7)                       /*條件3*/
and date(createon) between '2013-01-01' and '2018-12-31'   /*2013~2018*/
order by id desc;

/*註冊機器人2*/
drop table if exists plsport_playsport._problem_members_2;
create table plsport_playsport._problem_members_2 engine = myisam
SELECT userid FROM plsport_playsport.member
where userid like '%@%' and userid not like '%@yahoo.com.tw%' /*條件1*/
and date(createon) between '2013-01-01' and '2018-12-31'      /*2013~2018*/
order by nickname desc;

# 新的篩選機制, 記得先執行slice06_member_signin_log_archive.py 
#create table plsport_playsport._problem_members_3 engine = myisam
#SELECT userid FROM plsport_playsport._each_month_login_1;

/*新手買牌路徑的測試帳號*/
drop table if exists plsport_playsport._problem_members_4;
create table plsport_playsport._problem_members_4 engine = myisam
SELECT userid FROM plsport_playsport.member
where substr(nickname,1,3) in ('一路發','發大財','賺大錢') # 撈出此3個名字
and substr(nickname,4,1) REGEXP '^-?[0-9]+$'               # 第4個字要為數字
and createon between '2014-01-01 00:00:00' and '2014-03-17 17:00:00';

/*貼文機器人*/
drop table if exists plsport_playsport._problem_members_6;
create table plsport_playsport._problem_members_6 engine = myisam
SELECT userid FROM plsport_playsport.member
where userid like '%xiaojita%';

/*註冊機器人1 + 註冊機器人2 + 活死人 + 新手買牌路徑的測試帳號*/
insert ignore into plsport_playsport._problem_members_1 select * from plsport_playsport._problem_members_2;
# insert ignore into plsport_playsport._problem_members_1 select * from plsport_playsport._problem_members_3;
insert ignore into plsport_playsport._problem_members_1 select * from plsport_playsport._problem_members_4;
# insert ignore into plsport_playsport._problem_members_1 select * from plsport_playsport._problem_members_5;
insert ignore into plsport_playsport._problem_members_1 select * from plsport_playsport._problem_members_6;

drop table plsport_playsport._problem_members_2, plsport_playsport._problem_members_4, plsport_playsport._problem_members_6;

/*完成:需要被排除掉的名單*/
drop table if exists plsport_playsport._problem_members;
create table plsport_playsport._problem_members engine = myisam
SELECT userid 
FROM plsport_playsport._problem_members_1
group by userid;

drop table if exists plsport_playsport._problem_members_1;
ALTER TABLE plsport_playsport._problem_members ADD INDEX (`userid`);
