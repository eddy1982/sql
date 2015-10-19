into outfile :thumbsup:
-------------------------
```sh
SELECT 'a', 'b', 'c' union (
SELECT *
into outfile 'C:/Users/eddy/Desktop/xxxxx.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport.xxxxx);
```

alter table
-------------------------
```sh
ALTER TABLE plsport_playsport.xxxxx CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
```
```sh
ALTER TABLE plsport_playsport.xxxxx ADD INDEX (`userid`);
```
```sh
ALTER TABLE plsport_playsport.xxxxx convert to character set utf8 collate utf8_general_ci;
```
```sh
ALTER DATABASE plsport_playsport character set utf8 collate utf8_general_ci;
```

calculate percentile in mysql
-----------------------------
```
create table plsport_playsport._xxxxx engine = myisam
select userid, reply, round((cnt-rank+1)/cnt,2) as reply_percentile
from (SELECT userid, reply, @curRank := @curRank + 1 AS rank
	  FROM plsport_playsport._yyyyy, (SELECT @curRank := 0) r
	  order by reply desc) as dt,
	 (select count(distinct userid) as cnt from plsport_playsport._yyyyy) as ct;
```


PURGE BINARY LOGS Syntax
-------------------------
```sh
PURGE BINARY LOGS BEFORE '2014-12-31 00:00:00';
```




actionlog_uri mapping
-------------------------

```sh
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
```

purchase position mapping
-------------------------

```sh
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
```

user living city mapping
---------------------

```sh
create table plsport_playsport._city_info_ok_with_chinese engine = myisam
SELECT userid, city, 
			(case when (city =1) then '臺北市'
			when (city       =2) then'新北市'
			when (city       =3) then'桃園縣'
			when (city       =4) then'新竹市'
			when (city       =5) then'新竹縣'
			when (city       =6) then'苗栗縣'
			when (city       =7) then'臺中市'
			when (city       =8) then'臺中市'
			when (city       =9) then'彰化縣'
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
```




