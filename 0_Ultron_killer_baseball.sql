
# 賽季時間資料
SELECT allianceid, alliancename, year, pre_start, start, end 
FROM plsport_playsport.season
where allianceid in (1,2,6,9);




drop table if exists ultron_killer._prediction_3_p1_origin;
drop table if exists ultron_killer._prediction_8_p1_origin;
drop table if exists ultron_killer._prediction_91_p1_origin;
drop table if exists ultron_killer._prediction_92_p1_origin;
drop table if exists ultron_killer._prediction_94_p1_origin;
drop table if exists ultron_killer._prediction_97_p1_origin;

create table ultron_killer._prediction_3_p1_origin engine = myisam SELECT * FROM ultron_killer._prediction_3_p1;
create table ultron_killer._prediction_8_p1_origin engine = myisam SELECT * FROM ultron_killer._prediction_8_p1;
create table ultron_killer._prediction_91_p1_origin engine = myisam SELECT * FROM ultron_killer._prediction_91_p1;
create table ultron_killer._prediction_92_p1_origin engine = myisam SELECT * FROM ultron_killer._prediction_92_p1;
create table ultron_killer._prediction_94_p1_origin engine = myisam SELECT * FROM ultron_killer._prediction_94_p1;
create table ultron_killer._prediction_97_p1_origin engine = myisam SELECT * FROM ultron_killer._prediction_97_p1;

create table ultron_killer._prediction_3_p1_added_until_20170131 engine = myisam SELECT * FROM ultron_killer._prediction_3_p1;
create table ultron_killer._prediction_8_p1_added_until_20170131 engine = myisam SELECT * FROM ultron_killer._prediction_8_p1;
create table ultron_killer._prediction_91_p1_added_until_20170131 engine = myisam SELECT * FROM ultron_killer._prediction_91_p1;
create table ultron_killer._prediction_92_p1_added_until_20170131 engine = myisam SELECT * FROM ultron_killer._prediction_92_p1;
create table ultron_killer._prediction_94_p1_added_until_20170131 engine = myisam SELECT * FROM ultron_killer._prediction_94_p1;
create table ultron_killer._prediction_97_p1_added_until_20170131 engine = myisam SELECT * FROM ultron_killer._prediction_97_p1;

create table ultron_killer._prediction_3_p1_added_until_20161124 engine = myisam SELECT * FROM ultron_killer._prediction_3_p1;
create table ultron_killer._prediction_8_p1_added_until_20161124 engine = myisam SELECT * FROM ultron_killer._prediction_8_p1;
create table ultron_killer._prediction_91_p1_added_until_20161124 engine = myisam SELECT * FROM ultron_killer._prediction_91_p1;
create table ultron_killer._prediction_92_p1_added_until_20161124 engine = myisam SELECT * FROM ultron_killer._prediction_92_p1;
create table ultron_killer._prediction_94_p1_added_until_20161124 engine = myisam SELECT * FROM ultron_killer._prediction_94_p1;
create table ultron_killer._prediction_97_p1_added_until_20161124 engine = myisam SELECT * FROM ultron_killer._prediction_97_p1;



drop table if exists ultron_killer._prediction_p5_all_alliance_origin_20170218;
create table ultron_killer._prediction_p5_all_alliance_origin_20170218 engine = myisam
SELECT * FROM ultron_killer._prediction_p5_all_alliance;

drop table if exists ultron_killer._prediction_p5_all_alliance_added_20170218;
create table ultron_killer._prediction_p5_all_alliance_added_20170218 engine = myisam
SELECT * FROM ultron_killer._prediction_p5_all_alliance;

rename table ultron_killer._prediction_p5_all_alliance_added_20170218 to ultron_killer._prediction_p5_all_alliance_added_20170218_until_20140131;

drop table if exists ultron_killer._prediction_p5_all_alliance_added_20170219_until_20161124;
create table ultron_killer._prediction_p5_all_alliance_added_20170219_until_20161124 engine = myisam
SELECT * FROM ultron_killer._prediction_p5_all_alliance;



drop table if exists ultron_killer._prediction_3_p1;
drop table if exists ultron_killer._prediction_8_p1;
drop table if exists ultron_killer._prediction_91_p1;
drop table if exists ultron_killer._prediction_92_p1;
drop table if exists ultron_killer._prediction_94_p1;
drop table if exists ultron_killer._prediction_97_p1;

create table ultron_killer._prediction_3_p1 engine = myisam select * from ultron_killer._prediction_3_p1_origin;
create table ultron_killer._prediction_8_p1 engine = myisam select * from ultron_killer._prediction_8_p1_origin;
create table ultron_killer._prediction_91_p1 engine = myisam select * from ultron_killer._prediction_91_p1_origin;
create table ultron_killer._prediction_92_p1 engine = myisam select * from ultron_killer._prediction_92_p1_origin;
create table ultron_killer._prediction_94_p1 engine = myisam select * from ultron_killer._prediction_94_p1_origin;
create table ultron_killer._prediction_97_p1 engine = myisam select * from ultron_killer._prediction_97_p1_origin;









# 棒球季奧創的最後規則2017-03-21
drop table if exists ultron_killer_rules._alliance_1_rules;
create table ultron_killer_rules._alliance_1_rules engine = myisam
SELECT * FROM ultron_killer._prediction_1_p4
where c >= 15 and r >= 0.60 and gametype = 11;

insert ignore into ultron_killer_rules._alliance_1_rules
SELECT * FROM ultron_killer._prediction_1_p4
where c >= 15 and r >= 0.58 and gametype = 12;

drop table if exists ultron_killer_rules._alliance_2_rules;
create table ultron_killer_rules._alliance_2_rules engine = myisam
SELECT * FROM ultron_killer._prediction_2_p4
where c >= 15 and r >= 0.60 and gametype = 11;

insert ignore into ultron_killer_rules._alliance_2_rules
SELECT * FROM ultron_killer._prediction_2_p4
where c >= 15 and r >= 0.58 and gametype = 12;

drop table if exists ultron_killer_rules._alliance_9_rules;
create table ultron_killer_rules._alliance_9_rules engine = myisam
SELECT * FROM ultron_killer._prediction_9_p4
where c >= 15 and r >= 0.60 and gametype = 11;

insert ignore into ultron_killer_rules._alliance_9_rules
SELECT * FROM ultron_killer._prediction_9_p4
where c >= 15 and r >= 0.63 and gametype = 12;


