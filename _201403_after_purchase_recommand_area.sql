/*************************************************************************
	購買後推廌專區的資料觀察
	需要:
		(1)predict_buyer
		(2)fix.playworker (排除工友帳號)

    購買後推廌專區:
    	2014-03-04開始a/b testing (3/4~3/25 實驗userid%10+1為8,9,10)
    	2014-03-27全面上線
    	
**************************************************************************/
use plsport_playsport;

select a.g, sum(a.buy_price) as total_revenue
from (
	SELECT buyerid, buy_date, buy_price, position, cons, substr(position,6,1) as g, substr(position,4,1) as p
	FROM plsport_playsport.predict_buyer x left join fix.playworker y on x.buyerid = y.userid
	where position <> '0' and buy_date between '2014-03-04 00:00:00' and '2014-03-25 00:00:00'
	and y.userid is null #排除工友帳號
	order by buyerid, buy_date desc) as a
group by a.g;

select a.g, a.p, sum(a.buy_price) as total_revenue #每個位置的收益(原版標, 主推連過, 讓分連過, 本月最佳勝率)
from (
	SELECT buyerid, buy_date, buy_price, position, cons, substr(position,6,1) as g, substr(position,4,1) as p
	FROM plsport_playsport.predict_buyer x left join fix.playworker y on x.buyerid = y.userid
	where position <> '0' and buy_date between '2014-03-04 00:00:00' and '2014-03-25 00:00:00'
	and y.userid is null
	order by buyerid, buy_date desc) as a
group by a.g, a.p;

select a.g, count(a.buyerid) as c #購買次數包含用抵用券的人
from (
	SELECT buyerid, buy_date, buy_price, position, cons, substr(position,6,1) as g, substr(position,4,1) as p
	FROM plsport_playsport.predict_buyer x left join fix.playworker y on x.buyerid = y.userid
	where position <> '0' and buy_date between '2014-03-04 00:00:00' and '2014-12-31 00:00:00'
	and y.userid is null
	order by buyerid, buy_date desc) as a 
group by a.g;




/*----------------------------------------------------------------------------
	產出table版
----------------------------------------------------------------------------*/
create table plsport_playsport._after_purchase_recommand_area engine = myisam
select c.g, c.buyerid, sum(c.buy_price) as revenue, 
       (case when (c.g in(8,9,10)) then 'B' else 'A' end) as test
from (
	SELECT ((b.id%10)+1) as g, a.buyerid, date(a.buy_date) as d, a.buy_price
	FROM plsport_playsport.predict_buyer a left join plsport_playsport.member b on a.buyerid = b.userid
	where a.buy_date between '2014-03-04 00:00:00' and '2014-03-25 00:00:00'
    and a.buy_price <> 0) as c 
group by c.g, c.buyerid;

/*----------------------------------------------------------------------------
	輸出csv檔(內容同上)
----------------------------------------------------------------------------*/
select 'g', 'buyerid', 'revenue', 'test' union(
select c.g, c.buyerid, sum(c.buy_price) as revenue, 
       (case when (c.g in(8,9,10)) then 'B' else 'A' end) as test
into outfile 'C:/Users/1-7_ASUS/Desktop/_after_purchase_recommand_area.csv' 
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
from (
	SELECT ((b.id%10)+1) as g, a.buyerid, date(a.buy_date) as d, a.buy_price
	FROM plsport_playsport.predict_buyer a left join plsport_playsport.member b on a.buyerid = b.userid
	where a.buy_date between '2014-03-04 00:00:00' and '2014-03-25 00:00:00'
    and a.buy_price <> 0) as c 
group by c.g, c.buyerid);

select e.g, count(e.buyerid) as c
from (
	select c.g, c.buyerid, count(c.buy_price) as c, 
		(case when (c.g in(8,9,10)) then 'B' else 'A' end) as test
	from (
		SELECT ((b.id%10)+1) as g, a.buyerid, date(a.buy_date) as d, a.buy_price
		FROM plsport_playsport.predict_buyer a left join plsport_playsport.member b on a.buyerid = b.userid
		where a.buy_date between '2014-03-04 00:00:00' and '2014-03-25 00:00:00'
		and a.buy_price <> 0) as c 
	group by c.g, c.buyerid) as e
group by e.g;










/*************************************************************************
	update:2014/4/28
	購買後推廌專區的後續追蹤(5月,6月所使用的)

	需匯入
		(1)predict_buyer
		(2)predict_buyer_cons_split
		(3)predict_seller
**************************************************************************/

	/*-----------------------------------------
		  整理好表格
	-------------------------------------------*/
    #predict_buyer + predict_buyer_cons_split
/*
	create table plsport_playsport._predict_buyer_with_cons engine = myisam
	select c.id, c.buyerid, c.id_bought, d.sellerid ,c.buy_date , c.buy_price, c.position, c.cons, c.allianceid
	from (
		SELECT a.id, a.buyerid, a.id_bought, a.buy_date , a.buy_price, b.position, b.cons, b.allianceid
		FROM plsport_playsport.predict_buyer a left join plsport_playsport.predict_buyer_cons_split b on a.id = b.id_predict_buyer
		where buy_price <> 0) c left join plsport_playsport.predict_seller d on c.id_bought = d.id
	order by buy_date desc;
*/

	drop table if exists plsport_playsport._predict_buyer;
	drop table if exists plsport_playsport._predict_buyer_with_cons;

    #先predict_buyer + predict_buyer_cons_split
	create table plsport_playsport._predict_buyer engine = myisam
	SELECT a.id, a.buyerid, a.id_bought, a.buy_date , a.buy_price, b.position, b.cons, b.allianceid
	FROM plsport_playsport.predict_buyer a left join plsport_playsport.predict_buyer_cons_split b on a.id = b.id_predict_buyer
	where buy_price <> 0;

		ALTER TABLE plsport_playsport._predict_buyer ADD INDEX (`id_bought`);  

    #再+predict_seller
	create table plsport_playsport._predict_buyer_with_cons engine = myisam
	select c.id, c.buyerid, c.id_bought, d.sellerid ,c.buy_date , c.buy_price, c.position, c.cons, c.allianceid
	from plsport_playsport._predict_buyer c left join plsport_playsport.predict_seller d on c.id_bought = d.id
	order by buy_date desc;


/*-----------------------------------------
	 開始統計
-------------------------------------------*/

create table plsport_playsport._member_with_group engine = myisam
SELECT ((id%10)+1) as g, userid 
FROM plsport_playsport.member;

	ALTER TABLE plsport_playsport._predict_buyer_with_cons CHANGE `buyerid` `buyerid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '購買者userid';
	ALTER TABLE plsport_playsport._predict_buyer CHANGE `buyerid` `buyerid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '購買者userid';
	ALTER TABLE plsport_playsport._member_with_group ADD INDEX (`userid`);
	ALTER TABLE plsport_playsport._predict_buyer ADD INDEX (`buyerid`);


# 單獨把購買後推廌專區的銷售獨立出來
create table plsport_playsport._predict_buyer_with_cons_group engine = myisam
SELECT b.g, a.buyerid, a.buy_date, a.buy_price as price, a.position
FROM plsport_playsport._predict_buyer_with_cons a left join plsport_playsport._member_with_group b on a.buyerid = b.userid
where buy_date between '2014-05-14 00:00:00' and '2014-06-11 23:59:59'
and substr(position,1,3) = 'BRC';

	ALTER TABLE plsport_playsport._predict_buyer_with_cons_group CHANGE `buyerid` `buyerid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '購買者userid';
	ALTER TABLE plsport_playsport._predict_buyer_with_cons_group ADD INDEX (`buyerid`);

				# [2014-06-12] 次要TAB的追蹤任務, 查詢即可結束: TAB的推廌專區收益很低, 故直接判定a/b testing無效
				SELECT position, sum(price) as total_revenue 
				FROM plsport_playsport._predict_buyer_with_cons_group
				group by position
				order by position;


#各組在全站的收益
select c.g, sum(c.buy_price) as revenue
from (
	SELECT b.g, a.buyerid, a.buy_date, a.buy_price
	FROM plsport_playsport._predict_buyer a left join plsport_playsport._member_with_group b on a.buyerid = b.userid
	where buy_date between '2014-04-27 00:00:00' and '2014-05-27 23:59:59') as c
group by c.g;

#各組在購買後推廌專區的收益
SELECT position, sum(buy_price) as total_revenue
FROM plsport_playsport._predict_buyer_with_cons
where buy_date between '2014-04-27 00:00:00' and '2014-05-27 23:59:59'
and substr(position,1,3) = 'BRC'
group by position;











