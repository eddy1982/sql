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




