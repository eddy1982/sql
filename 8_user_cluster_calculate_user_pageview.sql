use actionlog_users_pv;

/* 每個月計算pv的處理, 要每月手動新增*/
# (1)pv
create table actionlog_users_pv.action_201411_users_pv engine = myisam
select a.userid, a.act_date, count(a.userid) as pv
from ( SELECT userid, date(time) as act_date FROM actionlog.action_201411) as a group by a.userid, a.act_date;
# (2)討論區
create table actionlog_users_pv.action_201411_users_pv_forum engine = myisam
select a.userid, a.act_date, count(a.userid) as pv_forum
from (SELECT userid, date(time) as act_date FROM actionlog.action_201411 where userid <> '' and uri like '%/forum%') as a group by a.userid, a.act_date;
# (3)即時比分
create table actionlog_users_pv.action_201411_users_pv_livescore engine = myisam
select a.userid, a.act_date, count(a.userid) as pv_livescore
from (SELECT userid, date(time) as act_date FROM actionlog.action_201411 where userid <> '' and uri like '%/livescore%') as a group by a.userid, a.act_date;
# (4)購牌專區
create table actionlog_users_pv.action_201411_users_pv_buy_predict engine = myisam
select a.userid, a.act_date, count(a.userid) as pv_buy_predict
from (SELECT userid, date(time) as act_date FROM actionlog.action_201411 where userid <> '' and uri like '%/buy_predict%') as a group by a.userid, a.act_date;
# (5)排行主推榜
create table actionlog_users_pv.action_201411_users_pv_billboard engine = myisam
select a.userid, a.act_date, count(a.userid) as pv_billboard
from (SELECT userid, date(time) as act_date FROM actionlog.action_201411 where userid <> '' and uri like '%/billboard%') as a group by a.userid, a.act_date;


/* 異常userid, 有需要再執行*/
delete from actionlog_users_pv.action_201411_users_pv             where userid like '%.php%'; /*8月有問題的userid, 駭客*/
delete from actionlog_users_pv.action_201411_users_pv_billboard   where userid like '%.php%'; /*8月有問題的userid, 駭客*/
delete from actionlog_users_pv.action_201411_users_pv_buy_predict where userid like '%.php%'; /*8月有問題的userid, 駭客*/
delete from actionlog_users_pv.action_201411_users_pv_forum       where userid like '%.php%'; /*8月有問題的userid, 駭客*/
delete from actionlog_users_pv.action_201411_users_pv_livescore   where userid like '%.php%'; /*8月有問題的userid, 駭客*/
delete from actionlog_users_pv.action_201411_users_pv             where userid = ''; 		  /*11月沒登入的visitor*/
delete from actionlog_users_pv.action_201411_users_pv_billboard   where userid = ''; 		  /*11月沒登入的visitor*/
delete from actionlog_users_pv.action_201411_users_pv_buy_predict where userid = ''; 		  /*11月沒登入的visitor*/
delete from actionlog_users_pv.action_201411_users_pv_forum       where userid = ''; 		  /*11月沒登入的visitor*/
delete from actionlog_users_pv.action_201411_users_pv_livescore   where userid = ''; 		  /*11月沒登入的visitor*/



/* 先新增, _users_daily_pv是每日活動表格, 從201308開始加*/
create table actionlog_users_pv._users_daily_pv             engine = myisam select * from actionlog_users_pv.action_201405_users_pv;
create table actionlog_users_pv._users_daily_pv_billboard   engine = myisam select * from actionlog_users_pv.action_201405_users_pv_billboard;
create table actionlog_users_pv._users_daily_pv_buy_predict engine = myisam select * from actionlog_users_pv.action_201405_users_pv_buy_predict;
create table actionlog_users_pv._users_daily_pv_forum       engine = myisam select * from actionlog_users_pv.action_201405_users_pv_forum;
create table actionlog_users_pv._users_daily_pv_livescore   engine = myisam select * from actionlog_users_pv.action_201405_users_pv_livescore;

/* 再insert其它月*/
insert ignore into actionlog_users_pv._users_daily_pv select * from actionlog_users_pv.action_201406_users_pv;
insert ignore into actionlog_users_pv._users_daily_pv select * from actionlog_users_pv.action_201407_users_pv;
insert ignore into actionlog_users_pv._users_daily_pv select * from actionlog_users_pv.action_201408_users_pv;
insert ignore into actionlog_users_pv._users_daily_pv select * from actionlog_users_pv.action_201409_users_pv;

insert ignore into actionlog_users_pv._users_daily_pv_billboard select * from actionlog_users_pv.action_201406_users_pv_billboard;
insert ignore into actionlog_users_pv._users_daily_pv_billboard select * from actionlog_users_pv.action_201407_users_pv_billboard;
insert ignore into actionlog_users_pv._users_daily_pv_billboard select * from actionlog_users_pv.action_201408_users_pv_billboard;
insert ignore into actionlog_users_pv._users_daily_pv_billboard select * from actionlog_users_pv.action_201409_users_pv_billboard;

insert ignore into actionlog_users_pv._users_daily_pv_buy_predict select * from actionlog_users_pv.action_201406_users_pv_buy_predict;
insert ignore into actionlog_users_pv._users_daily_pv_buy_predict select * from actionlog_users_pv.action_201407_users_pv_buy_predict;
insert ignore into actionlog_users_pv._users_daily_pv_buy_predict select * from actionlog_users_pv.action_201408_users_pv_buy_predict;
insert ignore into actionlog_users_pv._users_daily_pv_buy_predict select * from actionlog_users_pv.action_201409_users_pv_buy_predict;

insert ignore into actionlog_users_pv._users_daily_pv_forum select * from actionlog_users_pv.action_201406_users_pv_forum;
insert ignore into actionlog_users_pv._users_daily_pv_forum select * from actionlog_users_pv.action_201407_users_pv_forum;
insert ignore into actionlog_users_pv._users_daily_pv_forum select * from actionlog_users_pv.action_201408_users_pv_forum;
insert ignore into actionlog_users_pv._users_daily_pv_forum select * from actionlog_users_pv.action_201409_users_pv_forum;

insert ignore into actionlog_users_pv._users_daily_pv_livescore select * from actionlog_users_pv.action_201406_users_pv_livescore;
insert ignore into actionlog_users_pv._users_daily_pv_livescore select * from actionlog_users_pv.action_201407_users_pv_livescore;
insert ignore into actionlog_users_pv._users_daily_pv_livescore select * from actionlog_users_pv.action_201408_users_pv_livescore;
insert ignore into actionlog_users_pv._users_daily_pv_livescore select * from actionlog_users_pv.action_201409_users_pv_livescore;
/* 製作完_users_daily_pv就完成了, 篩選近120天內的SQL由8_user_cluster執行!*/










/*************************************************************************
	update:2014/4/1
    計算購牌專區的pv

**************************************************************************/
create table actionlog_users_pv.action_201301_users_pv_buy_predict_ engine = myisam
SELECT userid, date(time) as act_date FROM actionlog.action_201301 where userid <> '' and uri like '%buy_predict.php%';
create table actionlog_users_pv.action_201302_users_pv_buy_predict_ engine = myisam
SELECT userid, date(time) as act_date FROM actionlog.action_201302 where userid <> '' and uri like '%buy_predict.php%';
create table actionlog_users_pv.action_201303_users_pv_buy_predict_ engine = myisam
SELECT userid, date(time) as act_date FROM actionlog.action_201303 where userid <> '' and uri like '%buy_predict.php%';
create table actionlog_users_pv.action_201304_users_pv_buy_predict_ engine = myisam
SELECT userid, date(time) as act_date FROM actionlog.action_201304 where userid <> '' and uri like '%buy_predict.php%';
create table actionlog_users_pv.action_201305_users_pv_buy_predict_ engine = myisam
SELECT userid, date(time) as act_date FROM actionlog.action_201305 where userid <> '' and uri like '%buy_predict.php%';
create table actionlog_users_pv.action_201306_users_pv_buy_predict_ engine = myisam
SELECT userid, date(time) as act_date FROM actionlog.action_201306 where userid <> '' and uri like '%buy_predict.php%';
create table actionlog_users_pv.action_201307_users_pv_buy_predict_ engine = myisam
SELECT userid, date(time) as act_date FROM actionlog.action_201307 where userid <> '' and uri like '%buy_predict.php%';
create table actionlog_users_pv.action_201308_users_pv_buy_predict_ engine = myisam
SELECT userid, date(time) as act_date FROM actionlog.action_201308 where userid <> '' and uri like '%buy_predict.php%';
create table actionlog_users_pv.action_201309_users_pv_buy_predict_ engine = myisam
SELECT userid, date(time) as act_date FROM actionlog.action_201309 where userid <> '' and uri like '%buy_predict.php%';
create table actionlog_users_pv.action_201310_users_pv_buy_predict_ engine = myisam
SELECT userid, date(time) as act_date FROM actionlog.action_201310 where userid <> '' and uri like '%buy_predict.php%';
create table actionlog_users_pv.action_201311_users_pv_buy_predict_ engine = myisam
SELECT userid, date(time) as act_date FROM actionlog.action_201311 where userid <> '' and uri like '%buy_predict.php%';
create table actionlog_users_pv.action_201312_users_pv_buy_predict_ engine = myisam
SELECT userid, date(time) as act_date FROM actionlog.action_201312 where userid <> '' and uri like '%buy_predict.php%';
create table actionlog_users_pv.action_201401_users_pv_buy_predict_ engine = myisam
SELECT userid, date(time) as act_date FROM actionlog.action_201401 where userid <> '' and uri like '%buy_predict.php%';
create table actionlog_users_pv.action_201402_users_pv_buy_predict_ engine = myisam
SELECT userid, date(time) as act_date FROM actionlog.action_201402 where userid <> '' and uri like '%buy_predict.php%';
create table actionlog_users_pv.action_201403_users_pv_buy_predict_ engine = myisam
SELECT userid, date(time) as act_date FROM actionlog.action_201403 where userid <> '' and uri like '%buy_predict.php%';

create table actionlog_users_pv._users_pv_buy_predict_ engine = myisam
select * from actionlog_users_pv.action_201301_users_pv_buy_predict_;
insert ignore into actionlog_users_pv._users_pv_buy_predict_ select * from actionlog_users_pv.action_201302_users_pv_buy_predict_;
insert ignore into actionlog_users_pv._users_pv_buy_predict_ select * from actionlog_users_pv.action_201303_users_pv_buy_predict_;
insert ignore into actionlog_users_pv._users_pv_buy_predict_ select * from actionlog_users_pv.action_201304_users_pv_buy_predict_;
insert ignore into actionlog_users_pv._users_pv_buy_predict_ select * from actionlog_users_pv.action_201305_users_pv_buy_predict_;
insert ignore into actionlog_users_pv._users_pv_buy_predict_ select * from actionlog_users_pv.action_201306_users_pv_buy_predict_;
insert ignore into actionlog_users_pv._users_pv_buy_predict_ select * from actionlog_users_pv.action_201307_users_pv_buy_predict_;
insert ignore into actionlog_users_pv._users_pv_buy_predict_ select * from actionlog_users_pv.action_201308_users_pv_buy_predict_;
insert ignore into actionlog_users_pv._users_pv_buy_predict_ select * from actionlog_users_pv.action_201309_users_pv_buy_predict_;
insert ignore into actionlog_users_pv._users_pv_buy_predict_ select * from actionlog_users_pv.action_201310_users_pv_buy_predict_;
insert ignore into actionlog_users_pv._users_pv_buy_predict_ select * from actionlog_users_pv.action_201311_users_pv_buy_predict_;
insert ignore into actionlog_users_pv._users_pv_buy_predict_ select * from actionlog_users_pv.action_201312_users_pv_buy_predict_;
insert ignore into actionlog_users_pv._users_pv_buy_predict_ select * from actionlog_users_pv.action_201401_users_pv_buy_predict_;
insert ignore into actionlog_users_pv._users_pv_buy_predict_ select * from actionlog_users_pv.action_201402_users_pv_buy_predict_;
insert ignore into actionlog_users_pv._users_pv_buy_predict_ select * from actionlog_users_pv.action_201403_users_pv_buy_predict_;

drop table actionlog_users_pv.action_201301_users_pv_buy_predict_;
drop table actionlog_users_pv.action_201302_users_pv_buy_predict_;
drop table actionlog_users_pv.action_201303_users_pv_buy_predict_;
drop table actionlog_users_pv.action_201304_users_pv_buy_predict_;
drop table actionlog_users_pv.action_201305_users_pv_buy_predict_;
drop table actionlog_users_pv.action_201306_users_pv_buy_predict_;
drop table actionlog_users_pv.action_201307_users_pv_buy_predict_;
drop table actionlog_users_pv.action_201308_users_pv_buy_predict_;
drop table actionlog_users_pv.action_201309_users_pv_buy_predict_;
drop table actionlog_users_pv.action_201310_users_pv_buy_predict_;
drop table actionlog_users_pv.action_201311_users_pv_buy_predict_;
drop table actionlog_users_pv.action_201312_users_pv_buy_predict_;
drop table actionlog_users_pv.action_201401_users_pv_buy_predict_;
drop table actionlog_users_pv.action_201402_users_pv_buy_predict_;
drop table actionlog_users_pv.action_201403_users_pv_buy_predict_;

create table actionlog_users_pv._users_pv_buy_predict_ok engine = myisam
select a.userid, count(a.m) as c
from (
	SELECT userid, substr(act_date,1,7) as m
	FROM actionlog_users_pv._users_pv_buy_predict_) as a
group by a.userid;

ALTER TABLE  actionlog_users_pv._users_pv_buy_predict_ok CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  plsport_playsport.member CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

create table actionlog_users_pv._users_pv_buy_predict_ok_with_id engine = myisam
SELECT b.id, a.userid, a.c 
FROM actionlog_users_pv._users_pv_buy_predict_ok a left join plsport_playsport.member b on a.userid = b.userid;

create table actionlog_users_pv._users_pv_buy_predict_ok_with_id_createon engine = myisam
SELECT a.id, a.userid, a.c, date(b.createon ) as d
FROM actionlog_users_pv._users_pv_buy_predict_ok_with_id a left join plsport_playsport.member b on a.id = b.id;



















