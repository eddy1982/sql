/*************************************************************************
	update: 2014/3/24 
    從購牌者中，了解從購牌專區買牌者與從非購牌專區者的購買路徑


**************************************************************************/
use plsport_playsport;

/*(1)*/
create table plsport_playsport._who_buy_predict engine = myisam
SELECT userid, sum(amount) as total_spent 
FROM plsport_playsport.pcash_log
where date between '2014-03-10 00:00:00' and '2014-03-11 23:59:59'
and payed = 1 and type = 1
group by userid;
/*(2)*/
create table actionlog._action engine = myisam
select id, userid, uri, time from actionlog.action_201403  #記得要改掉
where time between '2014-03-10 00:00:00' and '2014-03-11 23:59:59'
and userid <> ' ';

	ALTER TABLE plsport_playsport._who_buy_predict ADD INDEX (`userid`); 
	ALTER TABLE actionlog._action ADD INDEX (`userid`); 
	ALTER TABLE plsport_playsport._who_buy_predict CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
	ALTER TABLE actionlog._action CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

/*(1)join(2)*/
create table actionlog._action_with_who_buy_predict engine = myisam
select a.id, a.userid, a.uri, a.time 
from actionlog._action a inner join plsport_playsport._who_buy_predict b on a.userid = b.userid;

/*捷取出uri的.php檔名*/
create table actionlog._action_with_who_buy_predict_php engine = myisam
select a.id, a.userid, (case when (a.uri_1='') then 'index' else a.uri_1 end ) as uri_2, a.time
from (
	SELECT id, userid, uri, substr(uri,2, (locate('.php',uri))-2) as uri_1, time 
	FROM actionlog._action_with_who_buy_predict) as a;

/*各頁的pv加總*/
SELECT uri_2, count(id) as c 
FROM actionlog._action_with_who_buy_predict_php
group by uri_2;

/*所有買牌者-551*/
SELECT userid, count(id) as c
FROM actionlog._action_with_who_buy_predict_php
group by userid;

/*有在用購牌專區的人-232*/
SELECT userid, count(id) as c 
FROM actionlog._action_with_who_buy_predict_php
where uri_2 = 'buy_predict'
group by userid;

/*沒有在用購牌專區的人(log)-319*/
select d.userid, count(d.id) as c
from (
	SELECT a.id, a.userid, a.uri_2, a.time
	FROM actionlog._action_with_who_buy_predict_php a left join (
		SELECT userid, count(id) as c
		FROM actionlog._action_with_who_buy_predict_php
		where uri_2 = 'buy_predict'
		group by userid) as b on a.userid = b.userid
	where b.userid is null) as d
group by d.userid;

/*有在用購牌專區的人(log)-232*/
select d.userid, count(d.id) as c 
from (
	SELECT a.id, a.userid, a.uri_2, a.time
	FROM actionlog._action_with_who_buy_predict_php a inner join (
		SELECT userid, count(id) as c 
		FROM actionlog._action_with_who_buy_predict_php
		where uri_2 = 'buy_predict'
		group by userid) as b on a.userid = b.userid) as d
group by d.userid;

/*---沒有在用購牌專區的人(log) - group by uri*/
SELECT d.uri_2, count(d.id) as c
from (
	SELECT a.id, a.userid, a.uri_2, a.time
	FROM actionlog._action_with_who_buy_predict_php a left join (
		SELECT userid, count(id) as c
		FROM actionlog._action_with_who_buy_predict_php
		where uri_2 = 'buy_predict'
		group by userid) as b on a.userid = b.userid
	where b.userid is null) as d
group by d.uri_2;

/*---有在用購牌專區的人(log) - group by uri*/
SELECT d.uri_2, count(d.id) as c
from (
	SELECT a.id, a.userid, a.uri_2, a.time
	FROM actionlog._action_with_who_buy_predict_php a inner join (
		SELECT userid, count(id) as c 
		FROM actionlog._action_with_who_buy_predict_php
		where uri_2 = 'buy_predict'
		group by userid) as b on a.userid = b.userid) as d
group by d.uri_2;


select sum(x.total_spent) as total_revenue
from plsport_playsport._who_buy_predict x inner join (
	select d.userid, count(d.id) as c
	from (
		SELECT a.id, a.userid, a.uri_2, a.time
		FROM actionlog._action_with_who_buy_predict_php a left join (
			SELECT userid, count(id) as c
			FROM actionlog._action_with_who_buy_predict_php
			where uri_2 = 'buy_predict'
			group by userid) as b on a.userid = b.userid
		where b.userid is null) as d
	group by d.userid) as y on x.userid = y.userid;

select sum(x.total_spent) as total_revenue
from plsport_playsport._who_buy_predict x inner join (
	select d.userid, count(d.id) as c 
	from (
		SELECT a.id, a.userid, a.uri_2, a.time
		FROM actionlog._action_with_who_buy_predict_php a inner join (
			SELECT userid, count(id) as c 
			FROM actionlog._action_with_who_buy_predict_php
			where uri_2 = 'buy_predict'
			group by userid) as b on a.userid = b.userid) as d
	group by d.userid) as y on x.userid = y.userid;;


SELECT a.id, a.userid, a.uri_2, a.time
	FROM actionlog._action_with_who_buy_predict_php a inner join (
		SELECT userid, count(id) as c 
		FROM actionlog._action_with_who_buy_predict_php
		where uri_2 = 'buy_predict'
		group by userid) as b on a.userid = b.userid;


/*************************************************************************
	update:2014/3/25
	來輸出畫CHORD所需要的csv格式檔

**************************************************************************/

/*(1)輸出csv:沒有透過購牌專區在買預測的人*/
select 'id', 'userid', 'uri_2', 'time' union(
	SELECT a.id, a.userid, a.uri_2, a.time
	into outfile 'C:/Users/1-7_ASUS/Desktop/buyer_without_buypredict_php.csv' 
	fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
	FROM actionlog._action_with_who_buy_predict_php a left join (
		SELECT userid, count(id) as c
		FROM actionlog._action_with_who_buy_predict_php
		where uri_2 = 'buy_predict'
		group by userid) as b on a.userid = b.userid
	where b.userid is null);

/*(2)輸出csv:有透過購牌專區在買預測的人*/
select 'id', 'userid', 'uri_2', 'time' union(
	SELECT a.id, a.userid, a.uri_2, a.time
	into outfile 'C:/Users/1-7_ASUS/Desktop/buyer_with_buypredict_php.csv' 
	fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
	FROM actionlog._action_with_who_buy_predict_php a inner join (
		SELECT userid, count(id) as c 
		FROM actionlog._action_with_who_buy_predict_php
		where uri_2 = 'buy_predict'
		group by userid) as b on a.userid = b.userid);


select 'source', 'target', 'count' union(
SELECT source, next, count(source) as c
into outfile 'C:/Users/1-7_ASUS/Desktop/buyer_with_buypredict_php_ok.csv' 
fields terminated by ',' enclosed by '' lines terminated by '\r\n'
FROM plsport_playsport.use_prediction_php_from_excel
group by source, next);

select 'source', 'target', 'count' union(
SELECT source, next, count(source) as c
into outfile 'C:/Users/1-7_ASUS/Desktop/buyer_without_buypredict_php_ok.csv' 
fields terminated by ',' enclosed by '' lines terminated by '\r\n'
FROM plsport_playsport.not_use_prediction_php_from_excel
group by source, next);