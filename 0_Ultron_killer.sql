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
