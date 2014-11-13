create database user_cluster;
/*************************************************************************
	必要的資料表:
	(1)member_signin_log_arvhive
	(2)member
	(3)order_data
	(4)predict_buyer
	(5)predict_seller
	(6)p_recently (在prediction中, 要事先準備好最近4個月的預測, 開8_web_site_operation_analysis.sql)
	(7)forum (直接匯入就好)
	(8)forumcontent (直接匯入就好)

	***可以直接連續執行以下SQL, 但是要先把actionlog的actionlog_users_pv, prediction給整理好:
	1. [actionlog]匯入最近的之後, 開8_user_cluster_calculate_user_pageviwes.sql
		新增:
			(1)_users_daily_pv
			(2)_users_daily_pv_billboard
			(3)_users_daily_pv_buy_predict
			(4)_users_daily_pv_forum
			(5)_users_daily_pv_livescore
    2. [prediction]執行python匯入之後, 開8_web_site_operation_analysis.sql (製作p_recently)

*************************************************************************/

use user_cluster;
/*(1) 篩選近4個月有登入的所有會員*/
create table user_cluster._user engine = myisam
select *
from (
	select a.id, a.userid, a.signin_time, a.ip , a.recently, datediff(now(),a.recently) as last_login_date
	from (
		SELECT id, userid, signin_time, ip, max(signin_time) as recently 
		FROM plsport_playsport.member_signin_log_archive
		group by userid) as a ) as b
where b.last_login_date < 121
order by b.recently; 

/*(2) 撈出member的資訊*/
create table user_cluster._member engine = myisam
SELECT id, userid, nickname, createon
FROM plsport_playsport.member;

/*(3) 使用者消費的儲值記錄*/
create table user_cluster._spent engine = myisam
select b.userid, b.total_spent, b.redeem_count, round((b.total_spent/b.redeem_count),0) as avg_spent
from (
	select a.userid, sum(a.price) as total_spent, count(a.ordernumber) as redeem_count
	from (
		SELECT userid, createon as ordercrate, ordernumber, price, payway, sellconfirm
		FROM plsport_playsport.order_data /*儲值記錄*/
		where payway <> 7 and sellconfirm = 1 and createon between subdate(now(),120) and now() 
		order by createon ) as a 
	group by a.userid ) as b;

/*(4) 消費者買牌記錄-消費, 不是儲值, 是站內消費*/
create table user_cluster._predict_buyer engine = myisam
SELECT id, buyerid, buy_date, id_bought, buy_price
FROM plsport_playsport.predict_buyer /*使用者站內消費*/
where buy_date between subdate(now(),120) and now() 
order by buy_date desc;

/*(5) 殺手賣牌記錄-收入*/
create table user_cluster._predict_seller engine = myisam
SELECT id, sellerid, sale_date, sale_price, buyer_count 
FROM plsport_playsport.predict_seller
where sale_date between subdate(now(),180) and now() /*注意:6個月內*/
order by sale_date;

/*(5_1) 2013/12/17新增:使用者站內消費記錄*/
create table user_cluster._spent_in_site engine = myisam
SELECT buyerid as userid, sum(buy_price) as spent
FROM user_cluster._predict_buyer /*使用者站內消費*/
group by buyerid; 

/*(6) 點預測記錄 -要先使用4_web_site_operation_analysis.sql*/
create table user_cluster._prediction engine = myisam
SELECT userid, gameid, allianceid, gametype, createon, createDay as d
FROM prediction.p_recently
where createon between subdate(now(),120) and now()
order by createDay;

use user_cluster;
ALTER TABLE user_cluster._member         ADD INDEX (`userid`);
ALTER TABLE user_cluster._user           ADD INDEX (`userid`);
ALTER TABLE user_cluster._spent          ADD INDEX (`userid`);
ALTER TABLE user_cluster._spent_in_site  ADD INDEX (`userid`);
ALTER TABLE user_cluster._predict_buyer  ADD INDEX (`id_bought`);
ALTER TABLE user_cluster._predict_seller ADD INDEX (`id`);
ALTER TABLE  `_user`         CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  `_member`       CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  `_member`       CHANGE  `nickname`  `nickname` CHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  `_spent`        CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  `_spent_in_site`CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT  '購買者userid';


/*(1)join(2)=(main)*/
create table user_cluster._user_with_mem engine = myisam
SELECT b.id, a.userid, b.nickname, b.createon as join_date ,a.recently as last_login, a.last_login_date as last_login_days
FROM user_cluster._user a left join user_cluster._member b on a.userid = b.userid
where b.id is not null;

/*(main)join(3)*/
create table user_cluster._user_with_mem_spent engine = myisam
SELECT a.id, a.userid, a.nickname, a.join_date, a.last_login, a.last_login_days, b.total_spent as redeem_amount, b.redeem_count , b.avg_spent
FROM user_cluster._user_with_mem a left join user_cluster._spent b on a.userid = b.userid;

update user_cluster._user_with_mem_spent set redeem_amount = 0 where redeem_amount is null; /*取代null改為0*/
update user_cluster._user_with_mem_spent set redeem_count  = 0 where redeem_count is null;  /*取代null改為0*/
update user_cluster._user_with_mem_spent set avg_spent     = 0 where avg_spent is null;     /*取代null改為0*/

create table user_cluster._predcit_buyer_seller engine = myisam /*predict_buyer join predict_seller是為了要知道殺手賺了多少*/
SELECT a.id, a.buyerid, a.buy_date, a.id_bought, a.buy_price, b.sellerid, b.sale_date, b.sale_price, b.buyer_count
FROM user_cluster._predict_buyer a left join user_cluster._predict_seller b on a.id_bought = b.id;

/*(4-1)*/
create table user_cluster._seller_earn_total engine = myisam
SELECT id_bought, sellerid, sum(buy_price) as earn_total 
FROM user_cluster._predcit_buyer_seller
where sellerid is not null
group by sellerid;

/*(4-2)*/
create table user_cluster._buyer_count engine = myisam
SELECT id_bought, sellerid, count(id) as buyer_count
FROM user_cluster._predcit_buyer_seller
where sellerid is not null and buy_price <> 0
group by sellerid;

ALTER TABLE user_cluster._seller_earn_total ADD INDEX (`sellerid`);
ALTER TABLE user_cluster._buyer_count ADD INDEX (`sellerid`);
ALTER TABLE user_cluster._user_with_mem_spent ADD INDEX (`userid`);
ALTER TABLE  `_seller_earn_total` CHANGE  `sellerid`  `sellerid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT  '賣牌者userid';
ALTER TABLE  `_buyer_count` CHANGE  `sellerid`  `sellerid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT  '賣牌者userid';

create table user_cluster._temp engine = myisam
SELECT a.id, a.userid, a.nickname, a.join_date, a.last_login, a.last_login_days, a.redeem_amount, a.redeem_count, a.avg_spent, b.sellerid, b.earn_total
FROM user_cluster._user_with_mem_spent a left join user_cluster._seller_earn_total b on a.userid = b.sellerid;

ALTER TABLE user_cluster._temp ADD INDEX (`userid`);

create table user_cluster._user_with_mem_spent_earn engine = myisam
select c.id, c.userid, c.nickname, c.join_date, c.last_login, c.last_login_days, c.redeem_amount, c.redeem_count, c.avg_spent, c.earn_total, d.buyer_count
from user_cluster._temp as c left join user_cluster._buyer_count as d on c.userid = d.sellerid;

drop table _buyer_count, _seller_earn_total, _temp, _predcit_buyer_seller;

/*預測天數的計算*/
create table user_cluster._prediction_c engine = myisam
select a.userid, count(a.userid) as predict_count 
from (
	SELECT userid, d, count(userid) as predict_count 
	FROM user_cluster._prediction
	group by userid, d
	order by userid) as a
group by a.userid;

ALTER TABLE user_cluster._prediction_c ADD INDEX (`userid`);
ALTER TABLE user_cluster._user_with_mem_spent_earn ADD INDEX (`userid`);
ALTER TABLE `_prediction_c` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

create table user_cluster._user_with_mem_spent_earn_predict engine = myisam
select a.id, a.userid, a.nickname, a.join_date, a.last_login, a.last_login_days, a.redeem_amount, a.redeem_count, 
       a.avg_spent, a.earn_total, a.buyer_count, b.predict_count as predict_days_count
from user_cluster._user_with_mem_spent_earn a left join user_cluster._prediction_c b on a.userid = b.userid;

update user_cluster._user_with_mem_spent_earn_predict set predict_days_count = 0 where predict_days_count is null; /*取代null改為0*/

/*-------------------------------------------------------------------------------
	到目前為止, 表格已經有了(1)消費 (2)收入 (3)點預測 (4)加入玩運彩的時間等資訊,
	還剩下討論區互動度和網站使用度需要加入

	計算網站使用度, 以pageview來算
	要先去處理actionlog_users_pv裡的資料表
	使用8_user_cluster_calculate_user_pageview.sql
-------------------------------------------------------------------------------*/
create table user_cluster._users_pv engine = myisam
SELECT userid, sum(pv) as pv 
FROM actionlog_users_pv._users_daily_pv 
where act_date between subdate(now(),120) and now()/*近4個月的users pageviews, 如果沒有本月份的, 就還是取當下的前120天*/
group by userid; 

ALTER TABLE user_cluster._user_with_mem_spent_earn_predict ADD INDEX (`userid`);
ALTER TABLE user_cluster._users_pv ADD INDEX (`userid`);
ALTER TABLE  `_users_pv` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

create table user_cluster._user_with_mem_spent_earn_predict_pv engine = myisam
SELECT a.id, a.userid, a.nickname, a.join_date, a.last_login, a.last_login_days, a.redeem_amount, a.redeem_count, a.avg_spent, a.earn_total, 
       a.buyer_count, a.predict_days_count, b.pv
FROM user_cluster._user_with_mem_spent_earn_predict a left join user_cluster._users_pv b on a.userid = b.userid;

/*	2013/12/20新增更多的pv:*/
create table user_cluster._users_pv_billboard engine = myisam 	/*排行主推榜的pv*/
SELECT userid, sum(pv_billboard) as pv_billboard 
FROM actionlog_users_pv._users_daily_pv_billboard
WHERE act_date between subdate(now(),120) and now() group by userid;
create table user_cluster._users_pv_buy_predict engine = myisam /*購牌專區的pv*/
SELECT userid, sum(pv_buy_predict) as pv_buy_predict 
FROM actionlog_users_pv._users_daily_pv_buy_predict
WHERE act_date between subdate(now(),120) and now() group by userid;
create table user_cluster._users_pv_forum engine = myisam 		/*討論區的pv*/
SELECT userid, sum(pv_forum) as pv_forum
FROM actionlog_users_pv._users_daily_pv_forum
WHERE act_date between subdate(now(),120) and now() group by userid;
create table user_cluster._users_pv_livescore engine = myisam	/*即時比分的pv*/
SELECT userid, sum(pv_livescore) as pv_livescore
FROM actionlog_users_pv._users_daily_pv_livescore
WHERE act_date between subdate(now(),120) and now() group by userid;

ALTER TABLE user_cluster._users_pv_billboard   ADD INDEX (`userid`);
ALTER TABLE user_cluster._users_pv_buy_predict ADD INDEX (`userid`);
ALTER TABLE user_cluster._users_pv_forum       ADD INDEX (`userid`);
ALTER TABLE user_cluster._users_pv_livescore   ADD INDEX (`userid`);
ALTER TABLE  `_users_pv_billboard`   CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  `_users_pv_buy_predict` CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  `_users_pv_forum`       CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  `_users_pv_livescore`   CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

create table user_cluster._users_pv_others engine = myisam
select g.userid, g.pv_forum, g.pv_livescore, g.pv_buy_predict, h.pv_billboard
from (
	select e.userid, e.pv_forum, e.pv_livescore, f.pv_buy_predict
	from (
		select c.userid, c.pv_forum, d.pv_livescore
		from (
			select a.userid, b.pv_forum 
			from user_cluster._user a left join user_cluster._users_pv_forum b on a.userid = b.userid) as c 
			left join user_cluster._users_pv_livescore d on c.userid = d.userid) as e
			left join user_cluster._users_pv_buy_predict f on e.userid = f.userid) as g
			left join user_cluster._users_pv_billboard h on g.userid = h.userid;

/*	note: _user_with_mem_spent_earn_predict_pv注意有些users的pageview是null, 此原因是因為目前沒有12月的actionlog
	目前還不能執行計算前120天的pv, 只能1個月1個月算 */

/*	開始來處理討論區使用度*/

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

ALTER TABLE user_cluster._user_reply ADD INDEX (`userid`);
ALTER TABLE user_cluster._user_post_and_influence ADD INDEX (`userid`);
ALTER TABLE  `_user_reply` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  `_user_post_and_influence` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

create table user_cluster._user_with_mem_spent_earn_predict_pv_post engine = myisam
SELECT a.id, a.userid, a.nickname, a.join_date, a.last_login, a.last_login_days, a.redeem_amount, a.redeem_count, a.avg_spent, a.earn_total, a.buyer_count, 
       a.predict_days_count, a.pv, b.post_count, b.influence
FROM user_cluster._user_with_mem_spent_earn_predict_pv a left join user_cluster._user_post_and_influence b on a.userid = b.userid;

create table user_cluster._user_with_mem_spent_earn_predict_pv_post_reply engine = myisam
SELECT a.id, a.userid, a.nickname, a.join_date, a.last_login, a.last_login_days, a.redeem_amount, a.redeem_count, a.avg_spent, a.earn_total, a.buyer_count, 
       a.predict_days_count, a.pv, a.post_count, b.reply_count ,a.influence
FROM user_cluster._user_with_mem_spent_earn_predict_pv_post a left join user_cluster._user_reply b on a.userid = b.userid;

update user_cluster._user_with_mem_spent_earn_predict_pv_post_reply set post_count  = 0 where post_count is null; /*取代null改為0*/
update user_cluster._user_with_mem_spent_earn_predict_pv_post_reply set reply_count = 0 where reply_count is null; /*取代null改為0*/
update user_cluster._user_with_mem_spent_earn_predict_pv_post_reply set influence   = 0 where influence is null; /*取代null改為0*/

/*	2013/12/17新增:使用者站內消費記錄*/
ALTER TABLE user_cluster._user_with_mem_spent_earn_predict_pv_post_reply ADD INDEX (`userid`);
create table user_cluster._user_with_mem_spent_earn_predict_pv_post_reply_spent1 engine = myisam
select a.id, a.userid, a.nickname, a.join_date, a.last_login, a.last_login_days, a.redeem_amount, a.redeem_count, a.avg_spent, a.earn_total, a.buyer_count, 
       a.predict_days_count, a.pv, a.post_count, a.reply_count, a.influence, b.spent
from user_cluster._user_with_mem_spent_earn_predict_pv_post_reply a left join user_cluster._spent_in_site b on a.userid = b.userid;

/*	2013/12/20新增:其它的pv*/
ALTER TABLE user_cluster._users_pv_others ADD INDEX (`userid`);
ALTER TABLE user_cluster._user_with_mem_spent_earn_predict_pv_post_reply_spent1 ADD INDEX (`userid`);

create table user_cluster._user_with_mem_spent_earn_predict_pv_post_reply_spent1_morepv engine = myisam
select a.id, a.userid, a.nickname, a.join_date, a.last_login, a.last_login_days, a.redeem_amount, a.redeem_count, a.avg_spent, a.earn_total, a.buyer_count, 
       a.predict_days_count, a.pv, a.post_count, a.reply_count, a.influence, a.spent, b.pv_forum, b.pv_livescore, b.pv_buy_predict, b.pv_billboard
from user_cluster._user_with_mem_spent_earn_predict_pv_post_reply_spent1 a left join user_cluster._users_pv_others b on a.userid =  b.userid;

/*最後名單*/
create table user_cluster._main engine = myisam
SELECT id, userid, nickname, nickname as name1, join_date, last_login, last_login_days, redeem_amount, 
       redeem_count, avg_spent as avg_redeem, earn_total, buyer_count, predict_days_count,
	   pv, post_count, reply_count, influence, spent, pv_forum, pv_livescore, pv_buy_predict, pv_billboard
FROM user_cluster._user_with_mem_spent_earn_predict_pv_post_reply_spent1_morepv;

UPDATE user_cluster._main set userid = TRIM(userid);          #刪掉空白字完
UPDATE user_cluster._main set name1  = TRIM(name1);            #刪掉空白字完
update user_cluster._main set name1  = replace(name1, '.',''); #清除nickname奇怪的符號...
update user_cluster._main set name1  = replace(name1, ',','');
update user_cluster._main set name1  = replace(name1, 'php','');
update user_cluster._main set name1  = replace(name1, 'admin','');
update user_cluster._main set name1  = replace(name1, ';','');
update user_cluster._main set name1  = replace(name1, '%','');
update user_cluster._main set name1  = replace(name1, '/','');
update user_cluster._main set name1  = replace(name1, '\\','_');
update user_cluster._main set name1  = replace(name1, '+','');
update user_cluster._main set name1  = replace(name1, '-','');
update user_cluster._main set name1  = replace(name1, '*','');
update user_cluster._main set name1  = replace(name1, '#','');
update user_cluster._main set name1  = replace(name1, '&','');
update user_cluster._main set name1  = replace(name1, '$','');
update user_cluster._main set name1  = replace(name1, '^','');
update user_cluster._main set name1  = replace(name1, '~','');
update user_cluster._main set name1  = replace(name1, '!','');
update user_cluster._main set name1  = replace(name1, '?','');
update user_cluster._main set name1  = replace(name1, '"','');
update user_cluster._main set name1  = replace(name1, ' ','_');
update user_cluster._main set name1  = replace(name1, '@','at');
update user_cluster._main set name1  = replace(name1, ':','');
update user_cluster._main set name1  = replace(name1, '','_');
update user_cluster._main set name1  = replace(name1, '∼','_');
update user_cluster._main set name1  = replace(name1, 'циндаогрыжа','_');
update user_cluster._main set name1  = replace(name1, '','_');
update user_cluster._main set name1  = replace(name1, '�','_');
update user_cluster._main set name1  = replace(name1, '▽','_');

	/*直接輸出成文字檔*/
	/*userid和nickname不要太長, 匯出csv很常有問題*/
	select 'id', 'userid', 'name1', 'join_date', 'last_login', 'last_login_days', 'redeem_amount', 'redeem_count', 
     	   'avg_redeem', 'earn_total', 'buyer_count', 'predict_days_count', 'pv', 'post_count', 'reply_count', 
     	   'influence', 'spent', 'pv_forum', 'pv_livescore', 'pv_buy_predict', 'pv_billboard' union(
	select id, substr(userid,1,10) as userid, substr(name1,1,6) as name1, join_date, last_login, last_login_days, 
	 	   redeem_amount, redeem_count, avg_redeem, earn_total, buyer_count, predict_days_count, pv, post_count, 
     	   reply_count, influence, spent, pv_forum, pv_livescore, pv_buy_predict, pv_billboard
	into outfile 'C:/proc/r/user_cluster/users.txt' 
	fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
	from user_cluster._main);









/*
	接下來要執行R
*/

/*
	再把R輸出的csv進入database中 [已把以下2段SQL寫成python]
*/
TRUNCATE TABLE `user_cluster`.`cluster`;
LOAD DATA LOW_PRIORITY LOCAL INFILE 'C:\\Users\\1-7_ASUS\\Documents\\R\\user_cluster\\user_complete_with_only_cluster.csv' 
REPLACE INTO TABLE `user_cluster`.`cluster` FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES (`id`, `userid`, `g`);

drop table user_cluster.cluster_with_real_userid;
create table user_cluster.cluster_with_real_userid engine = myisam
SELECT a.id, b.userid, a.g
FROM user_cluster.cluster a left join plsport_playsport.member b on a.id = b.id;

create table user_cluster.d_start engine = myisam
SELECT id, userid, createon as d_start 
FROM plsport_playsport.member;

create table user_cluster.d_end engine = myisam
SELECT userid, max(signin_time) as d_end 
FROM plsport_playsport.member_signin_log_archive
where signin_time between subdate(now(),120) and now()
group by userid;

ALTER TABLE user_cluster.d_start ADD INDEX (`userid`);
ALTER TABLE user_cluster.d_end ADD INDEX (`userid`);

create table user_cluster.d_lifetime engine = myisam
SELECT b.id, a.userid, round(DATEDIFF(a.d_end,b.d_start)/31,0) as lifetime, 
	   (case when (round(DATEDIFF(a.d_end,b.d_start)/31,0)<1) then 'E' /*未滿1個月*/
             when (round(DATEDIFF(a.d_end,b.d_start)/31,0)<4) then 'D' /*1~3個月*/
             when (round(DATEDIFF(a.d_end,b.d_start)/31,0)<7) then 'C' /*4~6個月*/
             when (round(DATEDIFF(a.d_end,b.d_start)/31,0)<13) then 'B' /*7~12個月*/
             when (round(DATEDIFF(a.d_end,b.d_start)/31,0)>12) then 'A' /*1年以上*/end) as lifetime_s 
FROM user_cluster.d_start b left join user_cluster.d_end a on a.userid = b.userid;

ALTER TABLE user_cluster.d_lifetime ADD INDEX (`id`);

create table user_cluster._cluster_with_lifetime engine = myisam
SELECT a.id, a.userid, a.g, b.lifetime, b.lifetime_s
FROM user_cluster.cluster a left join user_cluster.d_lifetime b on a.id = b.id;

