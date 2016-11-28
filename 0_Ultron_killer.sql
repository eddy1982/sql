# 檢查是否有重覆的prediction被insert
SELECT * 
FROM calculate_pm.prediction_2016
where userid = 'a721120'
order by userid, createon desc;

select a.gametype, count(a.userid) as c
from (
	SELECT * 
	FROM calculate_pm.prediction_2016
	where gameid = '2016082510200'
	and allianceid = 1) as a
group by a.gametype;

select a.predict, count(a.userid) as c
from (
	SELECT * 
	FROM calculate_pm.prediction_2016
	where gameid = '2016082410281'
	and allianceid = 1
	and gametype = 11) as a
group by a.predict;




# 檢查預測內容, 如果winner被update為0, 那要不要依其它人的結果來rewrite回去呢?
SELECT * 
FROM ultron_killer._prediction_1_p1
where gameid =  '2016080410200'
and gametype = 11
group by userid
order by createon desc;

SELECT gameid, predict, winner 
FROM ultron_killer._prediction_1_p1
where gameid =  '2016080410200'
and gametype = 11
and winner <> 0
group by gameid, predict, winner;

select a.predict, count(userid)
from (
	SELECT *
	FROM ultron_killer._prediction_1_p1
	where gameid =  '2016082610215'
	and gametype = 11
	group by userid) as a
group by a.predict;






# [阿達教學]如果有10%的人預測此注會過,且統計出來的勝率是60%
SELECT * 
FROM ultron_killer._prediction_3_p3_3
where gametype = 11
and ratio_guest_small >= 0.3
and ratio_guest_small < 0.35;

SELECT * 
FROM ultron_killer._prediction_3_p3_3
where gametype = 11
and ratio_guest_small >= 0.3
and ratio_guest_small < 0.35
and win_result = 2;




select *
from (
	SELECT * 
	FROM ultron_killer._prediction_3_p3_3
	where gametype = 11
	and ratio_guest_small >= 0.3
	and ratio_guest_small < 0.35) as a
where a.win_ratio >= 0.3 and a.win_ratio < 0.35;


SELECT * 
FROM ultron_killer._prediction_3_p3_3
where gametype = 11
and ratio_guest_small >= 0.45
and ratio_guest_small < 0.50;
select *
from (
	SELECT * 
	FROM ultron_killer._prediction_3_p3_3
	where gametype = 11
	and ratio_guest_small >= 0.45
	and ratio_guest_small < 0.50) as a
where a.win_ratio >= 0.45 and a.win_ratio < 0.50;




drop table if exists ultron_killer.rule;
CREATE TABLE ultron_killer.rule 
( `sn`        int(10) NOT NULL, 
  `gameytpe`   int(10) NOT NULL,
  `gameytpe_c` VARCHAR(30) NOT NULL , 
  `alliance`   int(10) NOT NULL, 
  `alliance_c` VARCHAR(30) NOT NULL , 
  `scale_range1`  double(10,2) NOT NULL,
  `scale_range2`  double(10,2) NOT NULL,
  `total_games`   int(10) NOT NULL, 
  `win_games`     int(10) NOT NULL, 
  `win_percentage` double(10,2) NOT NULL
) ENGINE = MyISAM CHARACTER SET utf8 COLLATE utf8_general_ci;


SELECT * 
FROM ultron_killer.rule
where alliance = 1
and gametype = 11
order by sn;


# 檢查押客場和押主場的
# 押客場
SELECT sum(total_games) as total_games, sum(win_games) as win_games
FROM ultron_killer.rule 
where recentlyday = 1460
and gametype = 11
and alliance = 3;

# 押主場
SELECT sum(total_games) as total_games, sum(win_games) as win_games
FROM ultron_killer.rule_1
where recentlyday = 1460
and gametype = 11
and alliance = 3;

SELECT count(gameid) as game_count
FROM ultron_killer._prediction_3_p3_3
where gametype = 11
and ratio_guest_small >= 0.5
and ratio_guest_small < 0.55;

SELECT count(gameid) as game_count
FROM ultron_killer._prediction_3_p3_3
where gametype = 11
and ratio_guest_small >= 0.5
and ratio_guest_small < 0.55
and win_result = 2;










# 讓分和大小的盤分和賠率
SELECT gameid, gsn, hometeam, visitteam, iaheadgame, iaheadgame_w, iaheadgame_result
FROM plsport_playsport.games
where gameid regexp '^201608[0-9][0-9]1.*';

select a.iaheadgame, a.iaheadgame_w, count(gameid) as c
from (
	SELECT gameid, gsn, hometeam, visitteam, iaheadgame, iaheadgame_w, iaheadgame_result, ibiggame, ibiggame_w, ibiggame_result
	FROM plsport_playsport.games
	where gameid regexp '^201608[0-9][0-9]1.*') as a
group by a.iaheadgame, a.iaheadgame_w;

select a.ibiggame, a.ibiggame_w, count(gameid) as c
from (
	SELECT gameid, gsn, hometeam, visitteam, iaheadgame, iaheadgame_w, iaheadgame_result, ibiggame, ibiggame_w, ibiggame_result
	FROM plsport_playsport.games
	where gameid regexp '^201608[0-9][0-9]1.*') as a
group by a.ibiggame, a.ibiggame_w;


SELECT allianceid, gameid, gsn, hometeam, visitteam, iaheadgame, iaheadgame_w, iaheadgame_result, ibiggame, ibiggame_w, ibiggame_result
FROM plsport_playsport.games
where gameid regexp '^201608[0-9][0-9]1.*'
and ibiggame > 100;


# 讓分
SELECT iaheadgame, iaheadgame_w, count(gameid) as c 
FROM ultron_killer._game_2_detail_1
group by iaheadgame, iaheadgame_w;
# 大小
SELECT ibiggame, ibiggame_w, count(gameid) as c 
FROM ultron_killer._game_2_detail_1
group by ibiggame, ibiggame_w;


# 讓分
SELECT iaheadgame_1, iaheadgame_w_1, count(gameid) as c 
FROM ultron_killer._game_1_detail_2
group by iaheadgame_1, iaheadgame_w_1;
# 大小
SELECT ibiggame_1, ibiggame_w_1, count(gameid) as c 
FROM ultron_killer._game_1_detail_2
group by ibiggame_1, ibiggame_w_1;

ALTER TABLE ultron_killer._game_1_detail_2 ADD INDEX (`gameid`);

drop table if exists ultron_killer._prediction_1_p3_temp_1;
create table ultron_killer._prediction_1_p3_temp_1 engine = myisam
SELECT a.gameid, a.d, a.gt, a.gtName, a.gut_sml, a.hom_big, a.r_gut_sml, a.r_hom_big, a.usrCount, a.winCount, 
       a.winRatio, a.winResult, a.r_gut_sml1, a.r_hom_big1, 
       b.iaheadgame_1, b.iaheadgame_w_1, b.ibiggame_1, b.ibiggame_w_1
FROM ultron_killer._prediction_1_p3_temp a left join ultron_killer._game_1_detail_3 b on a.gameid = b.gameid;

SELECT r_gut_sml1, iaHead1, iaHeadw1, count(gameid) as c 
FROM ultron_killer._prediction_1_p3_temp_1
where gt = 11
group by r_gut_sml1, iaHead1, iaHeadw1;

SELECT r_gut_sml1, iaHead1, iaHeadw1, count(gameid) as c 
FROM ultron_killer._prediction_1_p3_temp_1
where gt = 11
and winResult = 1
group by r_gut_sml1, iaHead1, iaHeadw1;

SELECT r_gut_sml1, iaHead1, iaHeadw1, count(gameid) as win_c 
FROM ultron_killer._prediction_1_p3_temp_1
WHERE gt = 11
and winResult = 2
group by r_gut_sml1, iaHead1, iaHeadw1;









drop table if exists ultron_killer._prediction_1_p3_temp_2;
create table ultron_killer._prediction_1_p3_temp_2 engine = myisam
select c.r_gut_sml1, c.iaHead1, c.iaHeadw1, c.c, c.win_c, round((c.win_c/c.c),2) as r
from 
	(SELECT a.r_gut_sml1, a.iaHead1, a.iaHeadw1, count(a.gameid) as c, COALESCE(b.win_c,0) as win_c
	 FROM ultron_killer._prediction_1_p3_temp_1 as a left join 
												(SELECT r_gut_sml1, iaHead1, iaHeadw1, count(gameid) as win_c 
												 FROM ultron_killer._prediction_1_p3_temp_1
												 WHERE gt = 11
												 and winResult = 2
												 group by r_gut_sml1, iaHead1, iaHeadw1) as b 
												 on a.r_gut_sml1 = b.r_gut_sml1
												 and a.iaHead1 = b.iaHead1
												 and a.iaHeadw1 = b.iaHeadw1
	 WHERE a.gt = 11
	 group by a.r_gut_sml1, a.iaHead1, a.iaHeadw1) as c;


SELECT r_gut_sml1, iaHead1, iaHeadw1, count(gameid) as win_c 
FROM ultron_killer._prediction_1_p3_temp_1
WHERE gt = 11
group by r_gut_sml1, iaHead1, iaHeadw1;


# 產生的新規則 - 以國際讓分為例
drop table if exists ultron_killer.__new_rule;
create table ultron_killer.__new_rule engine = myisam
SELECT * 
FROM ultron_killer._prediction_1_p4
where r >= 0.55
and c >= 15
and gametype = 11;

drop table if exists ultron_killer.__sample;
create table ultron_killer.__sample engine = myisam
SELECT * 
FROM ultron_killer._prediction_1_p3_temp_1
where d between '2016-04-01' and '2016-09-18'
and gt = 11;

drop table if exists ultron_killer.__result;
create table ultron_killer.__result engine = myisam
SELECT a.gameid, a.d, a.gt, a.gtName, a.r_gut_sml, a.r_hom_big, a.usrCount, a.winCount, a.winRatio, a.r_gut_sml1, a.r_hom_big1, a.winResult, a.winR,
       b.c, b.win_c, b.r, b.winResult as ourPredict, b.winR as ourPredictR
FROM ultron_killer.__sample a left join ultron_killer.__new_rule b 
on a.iaHead1 = b.info1
and a.iaHeadw1 = b.info2 
and a.r_hom_big1 = b.scale
where b.winResult = 1;
insert ignore into ultron_killer.__result
SELECT a.gameid, a.d, a.gt, a.gtName, a.r_gut_sml, a.r_hom_big, a.usrCount, a.winCount, a.winRatio, a.r_gut_sml1, a.r_hom_big1, a.winResult, a.winR,
       b.c, b.win_c, b.r, b.winResult as ourPredict, b.winR as ourPredictR
FROM ultron_killer.__sample a left join ultron_killer.__new_rule b 
on a.iaHead1 = b.info1
and a.iaHeadw1 = b.info2 
and a.r_gut_sml1 = b.scale
where b.winResult = 2;

select c.totalgame, c.corPredict, (c.corPredict/c.totalgame) as corRate
from (
	SELECT count(a.gameid) as totalgame, b.corPredict 
	FROM ultron_killer.__result as a, (SELECT count(gameid) as corPredict
										FROM ultron_killer.__result
										where winR = ourPredictR) as b) as c;


# 產生的新規則 - 以國際大小為例
# 所有的規則
drop table if exists ultron_killer.__new_rule;
create table ultron_killer.__new_rule engine = myisam
SELECT * 
FROM ultron_killer._prediction_1_p4
where r >= 0.55
and c >= 15
and gametype = 12;

# 決定要模擬預測的區間
drop table if exists ultron_killer.__sample;
create table ultron_killer.__sample engine = myisam
SELECT * 
FROM ultron_killer._prediction_1_p3_temp_1
where d between '2016-04-01' and '2016-10-03'
and gt = 12;

# 計算
drop table if exists ultron_killer.__result;
create table ultron_killer.__result engine = myisam
SELECT a.gameid, a.d, a.gt, a.gtName, a.r_gut_sml, a.r_hom_big, a.usrCount, a.winCount, a.winRatio, a.r_gut_sml1, a.r_hom_big1, a.winResult, a.winR,
       b.c, b.win_c, b.r, b.winResult as ourPredict, b.winR as ourPredictR
FROM ultron_killer.__sample a left join ultron_killer.__new_rule b 
on a.iBig1 = b.info1
and a.iBigw1 = b.info2 
and a.r_hom_big1 = b.scale
where b.winResult = 1; #押主大
insert ignore into ultron_killer.__result
SELECT a.gameid, a.d, a.gt, a.gtName, a.r_gut_sml, a.r_hom_big, a.usrCount, a.winCount, a.winRatio, a.r_gut_sml1, a.r_hom_big1, a.winResult, a.winR,
       b.c, b.win_c, b.r, b.winResult as ourPredict, b.winR as ourPredictR
FROM ultron_killer.__sample a left join ultron_killer.__new_rule b 
on a.iBig1 = b.info1
and a.iBigw1 = b.info2 
and a.r_gut_sml1 = b.scale
where b.winResult = 2; #押客小

select c.totalgame, c.corPredict, (c.corPredict/c.totalgame) as corRate
from (
	SELECT count(a.gameid) as totalgame, b.corPredict 
	FROM ultron_killer.__result as a, (SELECT count(gameid) as corPredict
										FROM ultron_killer.__result
										where winR = ourPredictR) as b) as c;






# 所以賽季的詳細資料/時間/結束
SELECT id, year, allianceid, alliancename, pre_start, start, end
FROM plsport_playsport.season
where allianceid in (1,2,3,91,92)
order by allianceid, id ;


SELECT dur, win_condition, avg(correct_rate) 
FROM ultron_killer._prediction_3_p5
where gametype = 11
group by dur, win_condition;
SELECT dur, win_condition, avg(correct_rate) 
FROM ultron_killer._prediction_3_p5
where gametype = 12
group by dur, win_condition;

SELECT dur, win_condition, avg(correct_rate) 
FROM ultron_killer._prediction_91_p5
where gametype = 11
group by dur, win_condition;
SELECT dur, win_condition, avg(correct_rate) , avg(apply_rate) 
FROM ultron_killer._prediction_91_p5
where gametype = 12
group by dur, win_condition;




# 正式的規則
drop table if exists ultron_killer_rules._alliance_91_rules;
create table ultron_killer_rules._alliance_91_rules
SELECT * 
FROM ultron_killer._prediction_91_p4
where c >= 15
and r >= 0.6;





# 模擬每小時的變化

SELECT id, userid, gameid, allianceid, gametype, predict, winner, createon,  hour(date_add(createon, INTERVAL 1 HOUR)) as h
FROM calculate_pm._test_
where gameid = '20161024911001'
order by createon ;

drop table if exists calculate_pm._test_1;
create table calculate_pm._test_1 engine = myisam
SELECT id, userid, gameid, allianceid, gametype, predict, winner, createon,  substr(date_add(createon, INTERVAL 1 HOUR),1,13) as h
FROM calculate_pm._test_
where gameid = '20161024911001'
order by createon ;

SELECT h, gametype, predict, count(id) as c 
FROM calculate_pm._test_1
group by h, gametype, predict;





# 把預測結果寫入google drive的文件中
create table ultron_killer._scale_91_rulematch_export engine = myisam
SELECT a.gameid, gsn, visitteam, hometeam, dateon, ihomeahead_p, ivisitahead_p, ihomebig_p, ivisitbig_p, 
       scale, info1, info2, c, win_c, r, act
FROM ultron_killer._scale_91_temp1 a left join ultron_killer._scale_91_rulematch b on a.gameid = b.gameid
where a.dateon between subdate(now(),1) and subdate(now(),-2)
and b.gameid is not null;

SELECT * FROM ultron_killer._scale_91_rulematch_export;

SELECT *
into outfile 'C:/Users/eddy/Google Drive/note/_scale_91_rulematch_export.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM ultron_killer._scale_91_rulematch_export;



# 只預測去年
# 20161107970300 [300]
# 2016-11-07 18:15
# 秋田北部喜悅 
# @ 東京電擊

SELECT * 
FROM ultron_killer._prediction_97_p4_gt11_sample
where gt = 11
and r_gut_sml1 = '0.35-0.40'
and iaHead1 = '主讓15以上'
and iaHeadw1 = '輸50%';

SELECT * 
FROM ultron_killer._prediction_97_p3_temp_1
where gt = 11
and r_gut_sml1 = '0.35-0.40'
and iaHead1 = '主讓15以上'
and iaHeadw1 = '輸50%';


# 開賽前盤分變動後
SELECT * 
FROM ultron_killer._prediction_97_p3_temp_1
where gt = 11
and r_hom_big1 = '0.60-0.65'
and iaHead1 = '主讓15以上'
and iaHeadw1 = '贏50% ';


SELECT * 
FROM ultron_killer._prediction_97_p3_temp_1
where gt = 11
and r_hom_big1 = '0.60-0.65'
and iaHead1 = '主讓15以上';



SELECT iaHeadw1, winResult, winR, count(gameid)
FROM ultron_killer._prediction_97_p3_temp_1
where gt = 11
and r_hom_big1 = '0.60-0.65'
and iaHead1 = '主讓15以上'
group by iaHeadw1, winResult;


SELECT  winResult, winR, count(gameid)
FROM ultron_killer._prediction_97_p3_temp_1
where gt = 11
and r_hom_big1 = '0.60-0.65'
and iaHead1 = '主讓15以上'
group by  winResult;






# 奧創的勝率 (從2016-10-26開始)
select c.allianceid, (c.win+c.lose) as c, round(c.win/(c.win+c.lose),2) as win_r
from (
	select b.allianceid, sum(b.win) as win, sum(b.lose) as lose
	from (
		select a.allianceid, (case when (a.winner = 1) then a.c else 0 end) as win,
							 (case when (a.winner = 2) then a.c else 0 end) as lose
		from (
			SELECT allianceid, winner, count(id) as c
			FROM ultron_killer_rules._ultron_history
            WHERE date(createon) between '2016-10-00' and '2016-11-21'
			group by allianceid, winner) as a) as b
	group by b.allianceid) as c;
    

# 奧創的勝率-依玩法來分 (從2016-10-26開始)
select c.allianceid, c.gametype, (c.win+c.lose) as c, round(c.win/(c.win+c.lose),2) as win_r
from (
	select b.allianceid, b.gametype, sum(b.win) as win, sum(b.lose) as lose
	from (
		select a.allianceid, a.gametype, (case when (a.winner = 1) then a.c else 0 end) as win,
										 (case when (a.winner = 2) then a.c else 0 end) as lose
		from (
			SELECT allianceid, gametype, winner, count(id) as c
			FROM ultron_killer_rules._ultron_history
			WHERE date(createon) between '2016-10-00' and '2016-11-21'
			and winner in (1,2)
			group by allianceid, gametype, winner) as a) as b
	group by b.allianceid, b.gametype) as c
group by c.allianceid, c.gametype;





    





create database ultron_killer_lab;

drop table if exists ultron_killer_lab._test;
create table ultron_killer_lab._test engine = myisam
SELECT * 
FROM calculate_pm.prediction_2016
where gameid = '2016110930400'
and gametype in ('11', '12');


drop table if exists ultron_killer_lab._test_1;
create table ultron_killer_lab._test_1 engine = myisam
select a.h, a.predict, count(a.id) as c
from (
	SELECT id, userid, gameid, predict, concat(substr(createon,1,13),':00:00') as h 
	FROM ultron_killer_lab._test
	where gametype = 11) as a
group by a.h, a.predict;



SELECT gameid 
FROM ultron_killer_lab._games_3
where date(createon) between '2016-11-07' and now();

SELECT * 
FROM ultron_killer_lab._prediction_alliance3
where gameid = '2016110930404'
and gametype = 12;

SELECT * 
FROM ultron_killer_lab._prediction_alliance3
where date(createon) = '2016-11-04' ;

SELECT * FROM ultron_killer_lab._games_3
where gameid = '2016110930404';










# 建立所有使用者點預測的原始資料
drop table if exists ultron_killer_lab._prediction_alliance3_temp;
create table ultron_killer_lab._prediction_alliance3_temp engine = myisam
SELECT id, gameid, allianceid, gametype, predict, winner, createon 
FROM calculate_pm.prediction_2016
where gametype in (11,12)
and gameid in (SELECT gameid
				FROM ultron_killer_lab._games_3
				where date(dateon) between '2016-06-10' and '2016-06-20'); #正規賽至賽季結束期間
                
insert ignore into ultron_killer_lab._prediction_alliance3
SELECT id, gameid, allianceid, gametype, predict, winner, createon 
FROM calculate_pm.prediction_2015
where gametype in (11,12)
and gameid in (SELECT gameid 
				FROM ultron_killer_lab._games_3
				where date(dateon) between '2016-06-10' and '2016-06-20'); #正規賽至賽季結束期間

ALTER TABLE ultron_killer_lab._prediction_alliance3 ADD INDEX (`gameid`);












# 先把上個賽季的預測資料準備好(NBA)
drop table if exists ultron_killer_lab._prediction_y20152016_alliance3;
create table ultron_killer_lab._prediction_y20152016_alliance3 engine = myisam
SELECT id, gameid, allianceid, gametype, predict, winner, createon 
FROM calculate_pm.prediction_2016
where gametype in (11,12)
and allianceid = 3
and date(createon) between '2015-10-28' and '2016-06-20';
insert ignore into ultron_killer_lab._prediction_y20152016_alliance3
SELECT id, gameid, allianceid, gametype, predict, winner, createon 
FROM calculate_pm.prediction_2015
where gametype in (11,12)
and allianceid = 3
and date(createon) between '2015-10-28' and '2016-06-20';
ALTER TABLE ultron_killer_lab._prediction_y20152016_alliance3 ADD INDEX (`gameid`);

# 先把上個賽季的預測資料準備好(冰球)
drop table if exists ultron_killer_lab._prediction_y20152016_alliance91;
create table ultron_killer_lab._prediction_y20152016_alliance91 engine = myisam
SELECT id, gameid, allianceid, gametype, predict, winner, createon 
FROM calculate_pm.prediction_2016
where gametype in (11,12)
and allianceid = 91
and date(createon) between '2015-10-08' and '2016-06-13';
insert ignore into ultron_killer_lab._prediction_y20152016_alliance91
SELECT id, gameid, allianceid, gametype, predict, winner, createon 
FROM calculate_pm.prediction_2015
where gametype in (11,12)
and allianceid = 91
and date(createon) between '2015-10-08' and '2016-06-13';
ALTER TABLE ultron_killer_lab._prediction_y20152016_alliance91 ADD INDEX (`gameid`);


