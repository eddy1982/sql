/*
updated: 2014/1/14 
SQL說明:
    (1) 記錄殺手的歷史(每期)勝率等資訊, 有在2014/1重新改寫過
    (2) 長期穩定殺手研究(殺手是那一期當上殺手的, 配合python)

2014/1/2備註:
    2013年度第一期殺手是83期(82期的有跨年度2012-2013), 
    2014跨年的殺手期數要找時間重新寫SQL.<<已經改寫完成, 2014/1/14會驗證到幾年前不會有bug

updated: 2014/1/14
    新增 (1)_mbillboard每月的勝率
         (2)_medal_fire_vols計算出每一期的上月勝率是那個月
             1. 原本merge6要先和_medal_fire_vols join merge7
             2. 接著把merge7 產生出pkey 變成merge8
             3. 再把merge8 join _mbillboard 成為 merge9
*/

create database killer; 
use killer;  /*殺手數據研究主要的database*/

# 需自行手動匯入:
#   (1) medal_fire
#   (2) medal_fire_vols
#   (3) mpbillboard
#   (4) pbillboard
#   (5) s_pbillboard
#   (6) winmpbillboard
#   (8) winwpbillboard
#   (9) wpbillboard


create table killer.medal_fire engine = myisam select * from plsport_playsport.medal_fire;
create table killer.medal_fire_vols engine = myisam select * from plsport_playsport.medal_fire_vols;
create table killer.mpbillboard engine = myisam select * from plsport_playsport.mpbillboard;        /*個人月勝率*/
create table killer.pbillboard engine = myisam select * from plsport_playsport.pbillboard;          /*個人歷史勝率*/
create table killer.s_pbillboard engine = myisam select * from plsport_playsport.s_pbillboard;      /*個人賽季勝率*/
create table killer.winmpbillboard engine = myisam select * from plsport_playsport.winmpbillboard;  /*今年度-月勝率*/ 
create table killer.winwpbillboard engine = myisam select * from plsport_playsport.winwpbillboard;  /*今年度-週2014 >=40 delete, 只有週的部分需要特別處理*/
create table killer.wpbillboard engine = myisam select * from plsport_playsport.wpbillboard;        /*今年度-週2014 >=40 delete, 只有週的部分需要特別處理*/

use killer;

/*匯入所需的table,從固定fix的資料庫copy過來, 此資料庫不太會變動*/
create table wpbillboard_2013 engine = myisam select * from fix.wpbillboard_2013;       /* 殺手勝率記錄2013, 已處理好*/
create table winwpbillboard_2013 engine = myisam select * from fix.winwpbillboard_2013; /* 殺手獲利記錄2013, 已處理好*/
create table wpbillboard_2012 engine = myisam select * from fix.wpbillboard_2012;       /* 殺手勝率記錄2012*/
create table winwpbillboard_2012 engine = myisam select * from fix.winwpbillboard_2012; /* 殺手獲利記錄2012*/
create table week_vol_mapping engine = myisam select * from fix.week_vol_mapping;       /* 週和殺手期數對應表*/
create table gametype engine = myisam select * from fix.gametype;                       /* 玩法對映的值*/
/*create table season engine = myisam select * from fix.season;*/                       /* 每年賽季記錄, 好像用不太到, 注意一下*/ 
/*匯入資料表結束---------------------*/


/*----------調整必要的table----------*/
use killer;
/*2014/1/10要來add2014的資料, 記得week也要+1*/
create table _wpbillboard_2014 engine = myisam/*勝率資訊2014*/
select id, userid, nickname, allianceid, alliancename, gametype, wingame, losegame, winpercentage, 
      (week+1) as week, (case when (allianceid > 0) then 2014 else 9999 end) as year
from wpbillboard where week < 40; /*2月之後可能要拿掉*/

create table _winwpbillboard_2014 engine = myisam/*獲利資訊2014*/
select id, userid, nickname, allianceid, alliancename, gametype, wingame, losegame, winearn,
      (week+1) as week, (case when (allianceid > 0) then 2014 else 9999 end) as year
from winwpbillboard where week < 40; /*2月之後可能要拿掉*/

/* 2013的week要+1, 因為第1週竟然是從0開始, 有問題, 要改成1 */
create table _wpbillboard_2013 engine = myisam/*勝率資訊2013*/
select id, userid, nickname, allianceid, alliancename, gametype, wingame, losegame, winpercentage, 
      (week+1) as week, (case when (allianceid > 0) then 2013 else 9999 end) as year
from wpbillboard_2013;

create table _winwpbillboard_2013 engine = myisam/*獲利資訊2013*/
select id, userid, nickname, allianceid, alliancename, gametype, wingame, losegame, winearn,
      (week+1) as week, (case when (allianceid > 0) then 2013 else 9999 end) as year
from winwpbillboard_2013;

/* 2012不需任何調整, 因為第1週就是從1開始*/
create table _wpbillboard_2012 engine = myisam/*勝率資訊2012*/
select id, userid, nickname, allianceid, alliancename, gametype, wingame, losegame, winpercentage, 
      week, (case when (allianceid > 0) then 2012 else 9998 end) as year
from wpbillboard_2012;

create table _winwpbillboard_2012 engine = myisam/*獲利資訊2012*/
select id, userid, nickname, allianceid, alliancename, gametype, wingame, losegame, winearn, week,
     (case when (allianceid > 0) then 2012 else 9998 end) as year
from winwpbillboard_2012;

/* merge三年的table, 並移除投注聯盟是0的怪異記錄*/
create table _wpbillboard_all engine = myisam/*勝率資訊*/
select * from _wpbillboard_2014 where year < 9990 union all
select * from _wpbillboard_2013 where year < 9990 union all
select * from _wpbillboard_2012 where year < 9990;

create table _winwpbillboard_all engine = myisam/*獲利資訊*/
select * from _winwpbillboard_2014 where year < 9990 union all
select * from _winwpbillboard_2013 where year < 9990 union all
select * from _winwpbillboard_2012 where year < 9990;

/* 新增變數總預測數*/
create table _wpbillboard_all_edited engine = myisam
select id, userid, nickname, allianceid, alliancename, gametype, wingame, losegame, (wingame + losegame) as totalgame, /*增加總注數的資料*/
       winpercentage, week, year 
from _wpbillboard_all;

/* 刪掉多餘用不到的table*/
drop table _winwpbillboard_2014, _winwpbillboard_2013, _winwpbillboard_2012;
drop table _wpbillboard_2014, _wpbillboard_2013, _wpbillboard_2012, _wpbillboard_all;

/* 換掉名字, 保持一致性*/
RENAME TABLE _wpbillboard_all_edited TO _wpbillboard_all;

/* 目前為主產生:
  (1)_winwpbillboard_all: 獲利的資料
  (2)_wpbillboard_all:    勝率的資料
*/

/* 調整玩法類型*/
create table _gametype engine = myisam select * from gametype;

create table _week_vol_mapping engine = myisam 
SELECT year, month, week_number, vol, count(year) as col_count 
FROM week_vol_mapping
group by year, month, week_number, vol;

create table _medal_fire_vols engine = myisam
select b.vol, b.date_start, b.announce_date, concat(substr(b.last_month,1,4),substr(b.last_month,6,2)) as yearmonth
from (
  select a.vol, a.date_start, a.announce_date, DATE_ADD(a.announce_date, INTERVAL -1 MONTH) AS last_month
  from (
    SELECT vol, date_start, DATE_ADD(date_start, INTERVAL 1 DAY) AS announce_date
    FROM killer.medal_fire_vols) as a) as b;
ALTER TABLE  `_medal_fire_vols` ADD INDEX (`yearmonth`);

/* 新增index*/
ALTER TABLE  `_wpbillboard_all` ADD INDEX (`year`);
ALTER TABLE  `_wpbillboard_all` ADD INDEX (`week`);
ALTER TABLE  `_winwpbillboard_all` ADD INDEX (`year`);
ALTER TABLE  `_winwpbillboard_all` ADD INDEX (`week`);
ALTER TABLE  `_week_vol_mapping` ADD INDEX (`year`);
ALTER TABLE  `_week_vol_mapping` ADD INDEX (`week_number`);

/* 完整的殺手資格數據*/
create table _wpbillboard_all_joined engine = myisam/*join勝率資訊和殺手期數*/
select a.id, a.userid, a.nickname, a.allianceid, a.alliancename, a.gametype, a.wingame, 
       a.losegame, a.totalgame, a.winpercentage, a.week, a.year, b.vol
from _wpbillboard_all a left join _week_vol_mapping b on a.year = b.year and a.week = b.week_number;

create table _winwpbillboard_all_joined engine = myisam/*join獲利資訊和殺手期數*/
select a.id, a.userid, a.nickname, a.allianceid, a.alliancename, a.gametype, a.wingame, 
       a.losegame, a.winearn, a.week, a.year, b.vol
from _winwpbillboard_all a left join _week_vol_mapping b on a.year = b.year and a.week = b.week_number;

create table _wpbillboard_all_joined_gametype engine = myisam/*join玩法wpbillboard*/
select a.userid, a.nickname, a.allianceid, a.alliancename, a.gametype, b.gametypename, b.gamehost, a.wingame, 
       a.losegame, a.totalgame, a.winpercentage, a.week, a.year, a.vol
from _wpbillboard_all_joined a left join _gametype b on a.gametype = b.gametype;

create table _winwpbillboard_all_joined_gametype engine = myisam/*join玩法winwpbillboard*/
select a.userid, a.nickname, a.allianceid, a.alliancename, a.gametype, b.gametypename, b.gamehost, a.winearn,
       a.week, a.year, a.vol
from _winwpbillboard_all_joined a left join _gametype b on a.gametype = b.gametype;
 
/* 刪掉多餘用不到的table*/
drop table _winwpbillboard_all;
drop table _winwpbillboard_all_joined;
drop table _wpbillboard_all;
drop table _wpbillboard_all_joined;

/* 換掉名字, 保持一致性*/
RENAME TABLE  _winwpbillboard_all_joined_gametype TO _winwpbillboard_all;
RENAME TABLE  _wpbillboard_all_joined_gametype TO _wpbillboard_all;

/* 處理pbillboard和s_pbillboard來join玩法和莊家*/ /*2014/1/10改到這裡*/
create table _pbillboard engine = myisam /*終身戰績*/
select a.userid, a.nickname, a.allianceid, a.alliancename, a.gametype, b.gametypename, b.gamehost, a.wingame, a.losegame, a.winpercentage
from pbillboard a left join _gametype b on a.gametype = b.gametype;

create table _s_pbillboard engine = myisam /*賽季戰績*/
select a.userid, a.nickname, a.allianceid, a.alliancename, a.gametype, b.gametypename, b.gamehost, a.wingame, a.losegame, a.winpercentage, a.year
from s_pbillboard a left join _gametype b on a.gametype = b.gametype;

ALTER TABLE  `_s_pbillboard` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL;
ALTER TABLE  `_s_pbillboard` CHANGE  `nickname`  `nickname` CHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL;
ALTER TABLE  `_s_pbillboard` CHANGE  `alliancename`  `alliancename` CHAR( 20 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL;
ALTER TABLE  `_s_pbillboard` CHANGE  `year`  `year` VARCHAR( 8 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL; 


/* 處理莊殺記錄medal_fire*/
/* -----先統一編碼至utf8*/
ALTER TABLE  `medal_fire` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL;
ALTER TABLE  `medal_fire` CHANGE  `nickname`  `nickname` VARCHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL;
/* -----再調整medal_fire*/
create table _medal_fire engine = myisam
select userid, nickname, vol, allianceid, alliancename, winpercentage as m_winratio, winearn as m_winearn, rank, 
       (case when (mode > 1) then 'int' else 'twn' end) as gamehost, backtoback,/*backtoback是當上莊殺的次數, 1:運彩盤, 2:國際盤*/
       (case when (rank > 0) then 'killer' else 'error' end) as killer
from medal_fire;

create table _medal_fire_2013 engine = myisam
select *
from _medal_fire
where vol>82 /*82期有跨年, 只需要新的一年之後的資料, 2013年開始*/
order by vol desc;


/* ===============組織資料===============*/
create table _user_wpbillboard engine = myisam          /*每個玩家的每週點戰績*/
select userid, nickname, allianceid, alliancename, gametype, gametypename, gamehost, sum(wingame) as wingame, sum(losegame) as losegame,
       week, year, vol
from _wpbillboard_all
where gametype in (1,2,11,12)                           /*不讓分玩法不能計算*/
group by userid, vol, allianceid, year, week, gamehost; /*每個玩家, 每期, 聯盟, 年, 週, 盤口已經獨立group起來*/

create table _user_wpbillboard_2013 engine = myisam     /*篩選今年度的殺手, 期數83(2013年)開始, 把去年的資料先砍去*/
select userid, nickname, allianceid, alliancename, gametype, gametypename, gamehost, wingame, losegame, (wingame + losegame) as totalgame, week ,year, vol
from _user_wpbillboard
where vol>82                                            /*82期有跨年*/
order by vol desc;
 
create table _user_winwpbillboard engine = myisam       /*每個玩家的每週點獲利*/
select userid, nickname, allianceid, alliancename, gametype, gametypename, gamehost, round(sum(winearn),2) as winearn, week, year, vol
from _winwpbillboard_all
where gametype in (1,2,11,12)                           /*不讓分玩法不能計算*/
group by userid, vol, allianceid, year, week, gamehost; /*每個玩家, 每期, 聯盟, 年, 週, 盤口已經獨立group起來*/

create table _user_winwpbillboard_2013 engine = myisam  /*篩選今年度的殺手, 期數83(2013年)開始, 把去年的資料先砍去*/
select *
from _user_winwpbillboard
where vol>82                                            /*82期有跨年*/
order by vol desc;

/* 
   update:2014/1/13
   重要:新發現的logic判斷, 每年的第1週如果為1, 那單數週必為評選第1週, 雙數週必為評選第2週
   2017會產生bug.
*/

/* 主要數據表:計算第1週點預測數*/
create table _user_wpbillboard_2013_first_week engine = myisam
select userid, nickname, vol, allianceid, alliancename, gamehost, wingame, totalgame as first_week
from _user_wpbillboard_2013
where week % 2 <> 0                                      /*單數是第1週, 2017年開始會有bug, 2017年單數變第2週*/
group by userid, allianceid, gamehost, vol;              /*殺手期數跨年的部分會有覆的record, 雖然group起來, 但並沒有相加, 故不影響*/
/* 主要數據表:計算第2週點預測數*/
create table _user_wpbillboard_2013_second_week engine = myisam
select userid, nickname, vol, allianceid, alliancename, gamehost, wingame, totalgame as second_week
from _user_wpbillboard_2013
where week % 2 = 0                                       /*偶數是第2週, 2017年開始會有bug, 2017年偶數變第1週*/
group by userid, allianceid, gamehost, vol;              /*殺手期數跨年的部分會有覆的record, 雖然group起來, 但並沒有相加, 故不影響*/
/* 主要數據表:計算第1週獲利*/
create table _user_winwpbillboard_2013_winearn_first_week engine = myisam
select userid, nickname, vol, allianceid, alliancename, gamehost, winearn as winearn1 /*獲利直接加起來*/
from _user_winwpbillboard_2013
where week % 2 <> 0 
group by userid, allianceid, gamehost, vol;
/* 主要數據表:計算第2週獲利*/
create table _user_winwpbillboard_2013_winearn_second_week engine = myisam
select userid, nickname, vol, allianceid, alliancename, gamehost, winearn as winearn2 /*獲利直接加起來*/
from _user_winwpbillboard_2013
where week % 2 = 0 
group by userid, allianceid, gamehost, vol;

/* 新增 2014/1/15:主要數據表:上月勝率*/
create table _mpbillboard engine = myisam
select b.userid, b.nickname, b.allianceid, b.alliancename, b.gamehost, b.wingame, b.losegame, round((b.wingame/(b.wingame+losegame)),2) as mwinratio, b.yearmonth
from (
  select a.userid, a.nickname, a.allianceid, a.alliancename, a.gamehost, sum(a.wingame) as wingame, sum(a.losegame) as losegame, a.yearmonth
  from (
    SELECT userid, nickname, allianceid, alliancename, gametype,
    (case when (gametype<4) then 'twn'
              when (gametype>10) then 'int' end) as gamehost, wingame, losegame, winpercentage, yearmonth 
    FROM mpbillboard
    where gametype in (1,2,3,11,12)) as a /*經確認後, 所有玩法都會被算在上月戰績裡*/
  group by a.userid, a.nickname, a.allianceid, a.gamehost, a.yearmonth) as b;

/* 準備merge第1週投注數outer join*/
create table _user_wpbillboard_2013_first_week1 engine = myisam
select userid, nickname, vol, allianceid, alliancename, gamehost
from _user_wpbillboard_2013_first_week;

/* 準備merge第2週投注數outer join*/
create table _user_wpbillboard_2013_second_week1 engine = myisam
select userid, nickname, vol, allianceid, alliancename, gamehost
from _user_wpbillboard_2013_second_week;

/* merge第1週和第2週投注數*/
create table _user_wpbillboard_2013_merge as 
select * from _user_wpbillboard_2013_first_week1 union all
select * from _user_wpbillboard_2013_second_week1;

/* merge第1週和第2週投注數_移除重覆的記錄*/
create table _user_wpbillboard_2013_merge_remove_duplicate engine = myisam
select userid, nickname, vol, allianceid, alliancename, gamehost, count(userid)
from _user_wpbillboard_2013_merge
group by userid, nickname, vol, allianceid, alliancename, gamehost;

/* 先刪掉用不到的tables*/
drop table _user_wpbillboard_2013_first_week1;
drop table _user_wpbillboard_2013_second_week1;
drop table _user_wpbillboard_2013_merge;

/* (1)在主要merge的資料表中加入pkey, 方便join*/
create table _user_wpbillboard_2013_merge_remove_duplicate1 engine = myisam
select concat(userid,nickname,vol,allianceid,gamehost) as pkey, userid, nickname, vol, allianceid, alliancename, gamehost
from _user_wpbillboard_2013_merge_remove_duplicate;

/* (2)在第1週的預測數中資料表中加入pkey, 方便join*/
create table _user_wpbillboard_2013_first_week1 engine = myisam
select concat(userid,nickname,vol,allianceid,gamehost) as pkey, userid, nickname, vol, allianceid, alliancename, gamehost, 
       wingame as wingame1, first_week as totalgame1 
from _user_wpbillboard_2013_first_week;

/* (3)在第2週的預測數中資料表中加入pkey, 方便join*/
create table _user_wpbillboard_2013_second_week1 engine = myisam
select concat(userid,nickname,vol,allianceid,gamehost) as pkey, userid, nickname, vol, allianceid, alliancename, gamehost, 
      wingame as wingame2, second_week as totalgame2
from _user_wpbillboard_2013_second_week;

/* (4)在第1週獲利中資料表中加入pkey, 方便join*/
create table _user_winwpbillboard_2013_winearn_first_week1 engine = myisam
select concat(userid,nickname,vol,allianceid,gamehost) as pkey, userid, nickname, vol, allianceid, alliancename, gamehost, winearn1
from _user_winwpbillboard_2013_winearn_first_week;

/* (5)在第2週獲利中資料表中加入pkey, 方便join*/
create table _user_winwpbillboard_2013_winearn_second_week1 engine = myisam
select concat(userid,nickname,vol,allianceid,gamehost) as pkey, userid, nickname, vol, allianceid, alliancename, gamehost, winearn2
from _user_winwpbillboard_2013_winearn_second_week;

/* (6)在殺手資格中資料表中加入pkey, 方便join*/
create table _medal_fire_2013_1 engine = myisam
select concat(userid,nickname,vol,allianceid,gamehost) as pkey, userid, nickname, vol, allianceid, gamehost, 
       m_winratio, m_winearn, rank, backtoback, killer
from _medal_fire_2013;

/* (7).....*/
create table _mpbillboard_1 engine = myisam
SELECT concat(userid,nickname,allianceid,gamehost,yearmonth) as pkey, userid, nickname, allianceid, alliancename, gamehost, mwinratio, yearmonth
FROM _mpbillboard;


/* index工作*/
ALTER TABLE  `_user_wpbillboard_2013_merge_remove_duplicate1` ADD INDEX (`pkey`);
ALTER TABLE  `_user_wpbillboard_2013_first_week1` ADD INDEX (`pkey`);
ALTER TABLE  `_user_wpbillboard_2013_second_week1` ADD INDEX (`pkey`);
ALTER TABLE  `_user_winwpbillboard_2013_winearn_first_week1` ADD INDEX (`pkey`);
ALTER TABLE  `_user_winwpbillboard_2013_winearn_second_week1` ADD INDEX (`pkey`);
ALTER TABLE  `_medal_fire_2013_1` ADD INDEX (`pkey`);
ALTER TABLE  `_mpbillboard_1` ADD INDEX (`pkey`);

/* (1)merge總表先來join第1週*/
create table _user_wpbillboard_2013_merge1 engine = myisam
select a.pkey, a.userid, a.nickname, a.vol, a.allianceid, a.alliancename, a.gamehost, 
     (case when (b.wingame1 is null) then 0 else b.wingame1 end) as wingame1, 
       (case when (b.totalgame1 is null) then 0 else b.totalgame1 end) as totalgame1
from _user_wpbillboard_2013_merge_remove_duplicate1 a left join _user_wpbillboard_2013_first_week1 b 
on a.pkey = b.pkey;

/* (2)再來join第2週*/
create table _user_wpbillboard_2013_merge2 engine = myisam
select a.pkey, a.userid, a.nickname, a.vol, a.allianceid, a.alliancename, a.gamehost, a.wingame1, a.totalgame1, 
       (case when (b.wingame2 is null) then 0 else b.wingame2 end) as wingame2, 
       (case when (b.totalgame2 is null) then 0 else b.totalgame2 end) as totalgame2
from _user_wpbillboard_2013_merge1 a left join _user_wpbillboard_2013_second_week1 b 
on a.pkey = b.pkey;

/* (3)再來join第1週獲利*/
create table _user_wpbillboard_2013_merge3 engine = myisam
select a.pkey, a.userid, a.nickname, a.vol, a.allianceid, a.alliancename, a.gamehost, a.wingame1, a.totalgame1, a.wingame2, a.totalgame2, round(b.winearn1,2) as winearn1
from _user_wpbillboard_2013_merge2 a left join _user_winwpbillboard_2013_winearn_first_week1 b 
on a.pkey = b.pkey;

/* (4)再來join第2週獲利*/
create table _user_wpbillboard_2013_merge4 engine = myisam
select a.pkey, a.userid, a.nickname, a.vol, a.allianceid, a.alliancename, a.gamehost, a.wingame1, a.totalgame1, a.wingame2, a.totalgame2, a.winearn1, round(b.winearn2,2) as winearn2
from _user_wpbillboard_2013_merge3 a left join _user_winwpbillboard_2013_winearn_second_week1 b 
on a.pkey = b.pkey;

/* (5)再來join殺手資格*/
create table _user_wpbillboard_2013_merge5 engine = myisam
select a.pkey, a.userid, a.nickname, a.vol, a.allianceid, a.alliancename, a.gamehost, a.wingame1, a.totalgame1, a.wingame2, a.totalgame2, a.winearn1, a.winearn2,
     b.m_winratio, b.m_winearn, b.rank, b.backtoback, b.killer
from _user_wpbillboard_2013_merge4 a left join _medal_fire_2013_1 b 
on a.pkey = b.pkey;

/* (6)修正殺手資料, 完成*/
create table _user_wpbillboard_2013_merge6 engine = myisam
select pkey, userid, nickname, vol, allianceid, alliancename, gamehost, totalgame1 as week1, totalgame2 as week2,
       (totalgame1+totalgame2) as totalgame, round((wingame1+wingame2)/(totalgame1+totalgame2),2) as winratio, 
     round((winearn1+winearn2),2) as winearn, round((m_winratio/100),2) as m_winratio, round(m_winearn,2) as m_winearn, rank, backtoback, killer
from _user_wpbillboard_2013_merge5;

/* (7)新增: join 上月勝率是那個月??*/
create table _user_wpbillboard_2013_merge7 engine = myisam
SELECT a.userid, a.nickname, a.vol, a.allianceid, a.alliancename, a.gamehost, a.week1, a.week2, 
       a.totalgame, a.winratio, a.winearn, a.m_winratio, a.m_winearn, a.rank, a.backtoback, a.killer, b.yearmonth
FROM killer._user_wpbillboard_2013_merge6 a left join _medal_fire_vols b on a.vol = b.vol;

/* (8)新增: 需要產生pkey*/
create table _user_wpbillboard_2013_merge8 engine = myisam
select concat(userid,nickname,allianceid,gamehost,yearmonth) as pkey, userid, nickname, vol, allianceid, alliancename, gamehost, 
       week1, week2, totalgame, winratio, winearn, m_winratio, m_winearn, rank, backtoback, killer, yearmonth
from _user_wpbillboard_2013_merge7;

ALTER TABLE  `_user_wpbillboard_2013_merge8` ADD INDEX (`pkey`);

/* (9)新增: join上月勝率, 並重新命名col, 完成!!!*/
create table _user_wpbillboard_2013_merge9 engine = myisam
select a.userid, a.nickname, a.vol, a.allianceid as aid, a.alliancename as aname, a.gamehost as gh, a.week1, a.week2, 
       a.totalgame, a.winratio, round(a.winearn,2) as winearn, a.yearmonth as ym,
       b.mwinratio as lwr, a.m_winratio as m_wr, round(a.m_winearn,2) as m_we, a.rank, a.backtoback as BtB, a.killer
from _user_wpbillboard_2013_merge8 a left join _mpbillboard_1 b on a.pkey = b.pkey;

UPDATE _user_wpbillboard_2013_merge9 set userid = TRIM(userid); #刪掉空白字完

ALTER TABLE  `_user_wpbillboard_2013_merge9` CHANGE  `aname`  `aname` CHAR( 20 ) CHARACTER SET big5 COLLATE big5_chinese_ci NOT NULL DEFAULT  '';
ALTER TABLE  `_user_wpbillboard_2013_merge9` CHANGE  `killer`  `killer` VARCHAR( 3 ) CHARACTER SET big5 COLLATE big5_chinese_ci NULL DEFAULT NULL ;
ALTER TABLE  `_user_wpbillboard_2013_merge9` CHANGE  `killer`  `killer` VARCHAR( 3 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ;

/*直接輸出至txt檔給R使用, 殺手人數好像不足的任務*/
select 'userid', 'vol', 'aid', 'aname', 'gh', 'week1', 'week2', 'totalgame', 'winratio', 'winearn', 'ym', 
       'lwr', 'm_wr', 'm_we', 'rank', 'BtB', 'killer' union(
select userid, vol, aid, aname, gh, week1, week2, totalgame, winratio, winearn, ym, lwr, m_wr, m_we, rank, BtB, killer
into outfile 'C:/Users/1-7_ASUS/Documents/R/201401_killer_not_enough/data.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' from _user_wpbillboard_2013_merge9);





/* 先刪掉用不到的tables*/
drop table _user_wpbillboard_2013_first_week;
drop table _user_wpbillboard_2013_first_week1;
drop table _user_wpbillboard_2013_second_week;
drop table _user_wpbillboard_2013_second_week1;
drop table _user_wpbillboard_2013_total_game;
drop table _user_wpbillboard_2013_total_game1;
drop table _user_winwpbillboard_2013_winearn;
drop table _user_winwpbillboard_2013_winearn1;
drop table _user_wpbillboard_2013_merge_remove_duplicate;
drop table _user_wpbillboard_2013_merge_remove_duplicate1;
drop table _user_wpbillboard_2013_merge1;
drop table _user_wpbillboard_2013_merge2;
drop table _user_wpbillboard_2013_merge3;
drop table _user_wpbillboard_2013_merge4;
drop table _medal_fire_2013_1;
/*到這裡結束the-end*/




/*2014新增: 各聯盟殺手人數變化查詢*/
SELECT vol, aid, aname, gh, count(userid) as killer_count
FROM killer._user_wpbillboard_2013_merge9
where vol between 83 and 108
and killer is not null
group by vol, gh, aid;




/*
  長期穩定殺手研究
*/

/*誰是曾經當過殺手, 至少需當過殺手, 或是已有長期穩定資格*/
create table _been_killer engine = myisam
select  a.userid, a.nickname, a.allianceid, a.alliancename, a.mode, a.gamehost, a.killer_count, 
        if(killer_count>2, 'stable_killer', 'killer') as killer_type
from (
  SELECT vol, userid, nickname, allianceid, alliancename, mode, 
      (case when(mode=1) then '北富'
      when(mode=2) then '國際' end) as gamehost, 
    count(userid) as killer_count
  FROM killer.medal_fire
  where backtoback is not null
  group by userid, nickname, allianceid, alliancename, mode
  order by userid) as a 
where a.killer_count > 0 /*至少要3次當上莊家殺手就是長期穩定*/
;

create table _main_int engine = myisam/*篩選國際盤mlb*/
SELECT * FROM killer._user_wpbillboard_2013_merge5
where allianceid in (1,2,3) /*1:MLB, 2:日棒, 3:NBA*/
and gamehost = '國際' /*可以換莊家*/
and vol between 83 and 104 /*熱門時段, 注意:只有83~104期*/
order by userid, vol
;
create table killer._main_int1 engine = myisam
SELECT userid, nickname, vol, allianceid, alliancename, gamehost,
       if(gamehost='北富',1,2) as mode, /*北富:1, 國際:2*/
       first_week, second_week, totalgame, winratio, winearn, 
       m_winratio, m_winearn, rank, backtoback, killer
FROM killer._main_int
;
drop table _main_int; rename table _main_int1 to _main_int;
ALTER TABLE  `_main_int` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  `_been_killer` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  `_main_int` ADD INDEX (userid, mode, allianceid);
ALTER TABLE  `_been_killer` ADD INDEX (userid, mode, allianceid);

create table _main_int_w_been_killer engine = myisam
SELECT a.userid, a.nickname, a.vol, a.allianceid, a.alliancename, if(a.gamehost='北富',1,2) as mode, a.gamehost, a.totalgame, a.winratio, a.winearn,
     a.m_winratio, a.m_winearn, a.rank, a.backtoback, a.killer,
       b.killer_count, b.killer_type
FROM killer._main_int a left join killer._been_killer b 
on a.userid = b.userid
and a.allianceid = b.allianceid
and a.mode = b.mode;

ALTER TABLE  `_main_int_w_been_killer` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  `_main_int_w_been_killer` ADD INDEX (userid, vol, mode, allianceid);

/*
  (1)_main_int_w_been_killer: users為普通人, 殺手, 穩定殺手, 但沒有詳細當上殺手是第幾期的資訊
  (2)_became_stable_killer_in_vol: 穩定殺手是第幾期當上殺手的
    然後:(1)left join(2)
*/

/*最後的OK表格*/
create table _main_int_w_been_killer_stable_info engine = myisam
select a.userid, a.nickname, a.vol, a.allianceid, a.alliancename, a.mode, a.gamehost, a.totalgame, 
  a.winratio, a.winearn, a.m_winratio, a.m_winearn, a.rank, a.backtoback,
  a.killer, a.killer_count, a.killer_type, b.become_stable_killer as becom_stable_killer_in_vol,
  (case when ((a.vol-b.become_stable_killer+1)>0) then 'yes' end) as iam_stable_killer
from _main_int_w_been_killer a left join _became_stable_killer_in_vol b 
on a.userid = b.userid 
and a.allianceid = b.allianceid 
and a.mode = b.mode
order by userid, allianceid, vol;

create table _main_int_w_been_killer_stable_info_for_export engine = myisam
select userid, vol, allianceid, mode, totalgame, winratio, winearn, round(m_winratio,2) as m_winratio, round(m_winearn,2) as m_winearn,
     rank, backtoback, (case when(killer is not null) then 'yes' end) as killer, killer_count, killer_type, 
     becom_stable_killer_in_vol, iam_stable_killer
from _main_int_w_been_killer_stable_info;


/*直接輸出至txt檔給R使用*/
select 'userid', 'vol', 'allianceid', 'mode', 
       'totalgame', 'winratio', 'winearn', 'm_winratio', 'm_winearn', 'rank', 'backtoback', 
       'killer', 'killer_count', 'killer_type', 'becom_stable_killer_in_vol', 'iam_stable_killer' union(
select userid, vol, allianceid, mode, 
       totalgame, winratio, winearn, coalesce(m_winratio, ''), coalesce(m_winearn, ''), coalesce(rank, ''), coalesce(backtoback, ''), 
       coalesce(killer, ''), coalesce(killer_count, ''), coalesce(killer_type, ''), 
     coalesce(becom_stable_killer_in_vol, ''), coalesce(iam_stable_killer, '')
into outfile 'C:/Users/1-7_ASUS/Documents/R/res_killernextvol2_stable/kill.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' from _main_int_w_been_killer_stable_info_for_export)
;


/*可用來對照目前的殺手榜*/
  SELECT * FROM killer._main_int_w_been_killer_stable_info
  where vol=104
  and killer is not null
  and allianceid=3
  order by m_winratio desc, m_winearn desc; /*先排序勝率,再排序獲利*/

/*暫用不到
    可以慢慢調整投注數,以不同的區間來分要再分成不同聯盟1,2,3; 程式已改寫
    create table _main_mlb_int_w_been_killer_cal engine = myisam
    select *
    from (
      SELECT userid, nickname, alliancename, gamehost, killer_count, killer_type,
        round(avg(totalgame),2) as avg_totalgame, round(avg(winratio),2) as avg_winratio, 
        max(winratio) as max_winratio, min(winratio) as min_winratio
      FROM killer._main_mlb_int_w_been_killer
      group by userid, nickname, alliancename, gamehost) as a;

    select 'userid', 'alliancename', 'gamehost', 'killer_count', 'killer_type', 'avg_totalgame', 'avg_winratio', 'max_winratio', 'min_winratio' union (
    select userid, alliancename, gamehost, 
    coalesce(killer_count, '') as killer_count, 
    coalesce(killer_type, '') as killer_type,
    avg_totalgame, avg_winratio, max_winratio, min_winratio
    into outfile 'C:/Users/1-7_ASUS/Documents/R/stable_killer_research/_main_mlb_int_w_been_killer_cal.txt'
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' FROM killer._main_mlb_int_w_been_killer_cal);
*/

/*
  COALESCE(yourfield, '') 把null換成空白字元

  直接輸出至txt檔給R使用
  select 'userid', 'allianceid', 'gamehost', 'buyer_count' union(
  select sellerid, allianceid, gamehost, sum(buyer_count) as buyer_count
  into outfile 'C:/Users/1-7_ASUS/Documents/R/res_killernextvol1/sell.txt'
  fields terminated by ',' enclosed by '"' lines terminated by '\r\n' from _predict_seller_vol_between_90_94
  group by sellerid, allianceid, gamehost)
  ;

  sum(if(vol=101, totalgame, null)) as v101t,
  sum(if(vol=102, totalgame, null)) as v101t
*/

/*
  目的:長期穩定殺手的銷售和一般殺手銷售的比較
  需要先匯入:
  (1) pcash_log
  (2) predict_seller
*/

create table _been_killer_aliid1_2_3 engine = myisam
SELECT *FROM killer._been_killer where allianceid in (1,2,3); /*只篩選MLB, 日棒, NBA*/

create table killer.pcash_log engine = myisam
SELECT * FROM plsport_playsport.pcash_log
where date between '2013-01-01 00:00:00' and '2013-10-31 23:59:59' and type = 1
order by date desc;

create table killer.predict_seller engine = myisam
SELECT * FROM plsport_playsport.predict_seller
where sale_date between '2013-01-01 00:00:00' and '2013-10-31 23:59:59'
order by sale_date desc;

SELECT * FROM killer.pcash_log;
SELECT * FROM killer.predict_seller;

ALTER TABLE  killer.pcash_log ADD INDEX (`id_this_type`);
ALTER TABLE  killer.predict_seller ADD INDEX (`id`);

create table killer._pcash_log_with_seller engine = myisam
select a.userid, a.amount, a.date, a.id_this_type, b.sellerid, b.mode, b.sale_allianceid, b.sale_gameid, b.sale_date, b.sale_price
from killer.pcash_log a left join killer.predict_seller b on a.id_this_type = b.id
where sale_allianceid in (1,2,3);

SELECT * FROM killer._pcash_log_with_seller;
SELECT * FROM killer._been_killer_aliid1_2_3;

ALTER TABLE killer._pcash_log_with_seller ADD INDEX (userid, mode, sale_allianceid);
ALTER TABLE killer._been_killer_aliid1_2_3 ADD INDEX (userid, mode, allianceid);

create table _pcash_log_with_seller_and_killer_state engine = myisam
select a.userid, a.amount, a.date, a.sellerid, a.mode, a.sale_allianceid, a.sale_gameid, a.sale_date, b.killer_type
from killer._pcash_log_with_seller a left join killer._been_killer_aliid1_2_3 b 
on a.sellerid = b.userid 
and a.mode = b.mode
and a.sale_allianceid = b.allianceid
where b.killer_type is not null/*因為pcash_log有全聯盟, 我們只要1,2,3, 所以要排掉killer_type = null*/;

select 'userid', 'amount', 'date', 'sellerid', 'mode', 'sale_allianceid', 'sale_gameid', 'sale_date', 'killer_type' union(
SELECT * 
into outfile 'C:/Users/1-7_ASUS/Documents/R/stable_killer_research/_pcash_log_with_seller_and_killer_state.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM killer._pcash_log_with_seller_and_killer_state);

create table _predict_seller_calculated engine = myisam
SELECT id, sellerid, mode, sale_allianceid, sale_gameid, sale_date, sale_price, buyer_count, (sale_price*buyer_count) as revenue
FROM killer.predict_seller 
where sale_allianceid in (1,2,3);

ALTER TABLE killer._predict_seller_calculated ADD INDEX (sellerid, mode, sale_allianceid);

create table _predict_seller_calculated_with_killer_state engine = myisam
select a.id, a.sellerid, a.mode, a.sale_allianceid, a.sale_gameid, a.sale_date, a.sale_price, a.buyer_count, a.revenue, b.killer_type
from _predict_seller_calculated a left join killer._been_killer_aliid1_2_3 b
on a.sellerid = b.userid 
and a.mode = b.mode
and a.sale_allianceid = b.allianceid;

select 'id', 'sellerid', 'mode', 'sale_allianceid', 'sale_gameid', 'sale_date', 'sale_price', 'buyer_count', 'revenue', 'killer_type' union(
select *
into outfile 'C:/Users/1-7_ASUS/Documents/R/stable_killer_research/_predict_seller_calculated_with_killer_state.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
from _predict_seller_calculated_with_killer_state);








/*殺手研究7/24----------------------------------------------------------------------------------------*/
/*txt檔匯出區-------------------*/
/*直接用merge5輸出至txt檔給R使用*/
select 'userid', 'vol', 'allianceid', 'gamehost', 'totalgame', 'winratio', 'winearn', 'killer' union(
select userid, vol, allianceid,
(case when (gamehost='國際') then 'int' 
      when (gamehost='北富') then 'fub' 
      else 'xxx' end) as gamehost, totalgame, winratio, round(winearn,2) as winearn, 
(case when (killer='殺手') then 'yes'
      else 'no' end) as killer
into outfile 'C:/Users/1-7_ASUS/Documents/R/res_killernextvol1/kill.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'from _user_wpbillboard_2013_merge5
where allianceid in (1,2,6,9)
and vol between 90 and 96)/*<-----要修改期數*/
;
/*計算殺手的賣牌數來評估狀況好不好*/   /*目前還不能自動產生, 需要注意*/
create table _predict_seller engine = myisam
select sellerid, 
(case when (mode=1) then 'fub'
      when (mode=2) then 'int'
      else 'xxx' end) as gamehost, sale_allianceid as allianceid, date(sale_date) as sale_date, sale_price, buyer_count
from predict_seller
;
create table _predict_seller_vol_between_90_94 engine = myisam
select sellerid, gamehost, allianceid, sale_date, sale_price, buyer_count
from _predict_seller
where allianceid in (1,2,6,9) /*只篩選出MLB,日棒,韓棒,中職*/
and sale_date between '2013-05-06 00:00:00' and '2013-07-27 23:59:59' /*區間是90期~94期, 共5期*//*<-----要修改期數*/
;
/*直接輸出至txt檔給R使用*/
select 'userid', 'allianceid', 'gamehost', 'buyer_count' union(
select sellerid, allianceid, gamehost, sum(buyer_count) as buyer_count
into outfile 'C:/Users/1-7_ASUS/Documents/R/res_killernextvol1/sell.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' from _predict_seller_vol_between_90_94
group by sellerid, allianceid, gamehost)
;

/*殺手研究7/24----------------------------------------------------------------------------------------*/

/* ===============查詢殺手===============*/
/* -----查詢勝率*/
select userid, nickname, allianceid, alliancename, gametype, gametypename, gamehost, sum(wingame) as wingame, sum(losegame) as losegame,
       week, year, vol
from _wpbillboard_all
where vol=94 and year=2013 and userid='0988327609' and allianceid=2 and gametype in (1,2,11,12)
group by vol, year, week, gamehost
order by gametype
;
select *
from _user_wpbillboard_2013_merge5
where userid='qqqno1' and allianceid=94
order by vol desc
;
/* -----查詢獲利*/
select userid, nickname, allianceid, alliancename, gametype, gametypename, gamehost, round(sum(winearn),2) as winearn ,week, year, vol
from _winwpbillboard_all
where vol=94 and year=2013 and userid='0988327609' and allianceid=2 and gametype in (1,2,11,12)
group by vol, year, week, gamehost
order by gametype
;
/* -----查詢總投注數*/
select userid, nickname, allianceid, alliancename, gametype, gametypename, gamehost, wingame, losegame, (wingame + losegame) as totalgame, winpercentage
from _pbillboard /*總勝率*/
where userid = '0988327609' and allianceid=2
order by gamehost
;
/* -----查詢季勝率*/
select userid, nickname, allianceid, alliancename, gametype, gametypename, gamehost, wingame, losegame, winpercentage, year
from _s_pbillboard /*季勝率*/
where userid = '0988327609' and allianceid=2
and year = 20132013
order by gamehost
;

/* -----研究一下賽季戰績*/
create table _s_pbillboard_test engine = myisam
select *
from _s_pbillboard
where allianceid in (1,2,3)
;

create table _s_pbillboard_r engine = myisam
select userid, allianceid, gametype, wingame, losegame, 
(wingame+losegame) as totalgame, round((winpercentage/100),2) as winratio, year
from _s_pbillboard
;

/*過去的舊玩法*/
create table _s_pbillboard_test1 engine = myisam
select *
from _s_pbillboard
where gametype in (51, 52, 53)
;

/*_7/16--研究最低注數, 只選出目前熱門的聯盟, 並只取到莊殺第94期, 不算95期*/
create table _user_wpbillboard_2013_merge5_july16 engine = myisam
SELECT * FROM _user_wpbillboard_2013_merge5
where vol<95
and allianceid in (1,2,4,6,9)
order by vol desc
;

/*捉出工友群們*/
create table _playworker engine = myisam
select *
from member
where type = 1
;

/*產生每期殺手第1天和最後1天的日期*/
create table _week_vol_mapping_min engine = myisam
select vol, min(full_date) as start_date
from week_vol_mapping 
group by vol
;
create table _week_vol_mapping_max engine = myisam
select vol, max(full_date) as end_date
from week_vol_mapping 
group by vol
;
create table _week_vol_mapping_date engine = myisam
select a.vol, a.start_date, b.end_date
from _week_vol_mapping_min a join _week_vol_mapping_max b on a.vol = b.vol
;

/*計算賽季勝率*/
create table _s_pbillboard_2013 engine = myisam
select userid, allianceid, gametype, gamehost, wingame, losegame, (wingame+losegame) as totalgame, winpercentage, year
from _s_pbillboard
where year = '20132013' and gametype in (1,2,11,12) and allianceid in (1,2,4,6,9)
;
create table _s_pbillboard_2013_calulation engine = myisam
SELECT userid, allianceid, gamehost, sum(wingame) as wingame, sum(losegame) as losegame, sum(totalgame) as totalgame, year
FROM _s_pbillboard_2013
group by userid, allianceid, gamehost
order by userid
;
create table _s_pbillboard_2013_calulation1 engine = myisam
select userid, allianceid, 
(case when (gamehost='國際') then 'int' 
      when (gamehost='北富') then 'fub' 
      else 'xxx' end) as gamehost,
wingame, losegame, totalgame, round((wingame/totalgame),2) as winratio, year
from _s_pbillboard_2013_calulation
;

SELECT * FROM ftp0722.predict_seller;

/*計算殺手的賣牌數來評估狀況好不好*/   /*目前還不能自動產生, 需要注意*/
create table _predict_seller_vol_between_90_93
select sellerid, mode, sale_allianceid, date(sale_date) as sale_date, sale_price, buyer_count
from predict_seller
where mode = 2 /*只篩選出國際盤*/
and sale_allianceid = 1 /*只篩選出MLB*/
and sale_date between '2013-05-06 00:00:00' and '2013-07-14 23:59:59' /*區間是90期~93期, 共4期*/
;

create table _predict_seller_vol_between_90_93_count
select sellerid, sum(buyer_count) as buyer_count from _predict_seller_vol_between_90_93
group by sellerid
;










# 以上超久沒動
# ===============================================================================================
# 2014-11-3 計算每期user所點的注數
# 必要tables:
#     (1)新製作的medal_killer_vol_mapping ~2014 ~grouped
#     (2)wpbillboard
# ===============================================================================================

create table fix.medal_killer_vol_mapping_2014 engine = myisam
SELECT * 
FROM fix.medal_killer_vol_mapping
where year(full_date) = 2014
and vol > 108; # 109期才沒有莊殺期數跨年

create table fix.medal_killer_vol_mapping_2014_grouped engine = myisam
SELECT vol, week_no, week_odd 
FROM fix.medal_killer_vol_mapping_2014
group by vol, week_no, week_odd;

create table plsport_playsport._wpbillboard_with_vol engine = myisam
SELECT a.id, a.userid, a.nickname, a.allianceid, a.alliancename, a.gametype, a.wingame, a.losegame, a.winpercentage, a.week, a.rankid, b.vol, b.week_odd
FROM plsport_playsport.wpbillboard a left join fix.medal_killer_vol_mapping_2014_grouped b on a.week = b.week_no
where vol is not null;

create table plsport_playsport._wpbillboard_with_vol_1 engine = myisam
SELECT userid, nickname, allianceid, alliancename, gametype, (case when (gametype<4) then 'TWN' else 'INT' end) as dish,
       wingame, losegame, winpercentage, week, rankid, vol, week_odd 
FROM plsport_playsport._wpbillboard_with_vol
where gametype <> 3; # 不讓分是不計算在戰績裡的

create table plsport_playsport._wpbillboard_with_vol_2 engine = myisam
SELECT userid, nickname, allianceid, alliancename, dish, vol, week, week_odd, sum(wingame) as wingame, sum(losegame) as losegame
FROM plsport_playsport._wpbillboard_with_vol_1
group by userid, allianceid, dish, vol, week, week_odd
order by dish, week, vol, userid, allianceid;

# 完成表1.每週完整注數
create table plsport_playsport._wpbillboard_with_vol_3 engine = myisam
SELECT userid, nickname, allianceid, alliancename, dish, vol, week, week_odd, wingame, losegame, (wingame+losegame) as totalgame
FROM plsport_playsport._wpbillboard_with_vol_2;

create table plsport_playsport._wpbillboard_with_vol_3_biweek engine = myisam
SELECT userid, nickname, allianceid, alliancename, dish, vol, sum(wingame) as wingame, sum(losegame) as losegame, sum(totalgame) as biweekgame 
FROM plsport_playsport._wpbillboard_with_vol_3
group by userid, allianceid, dish, vol;

# 完成表2.雙週注數/戰績
create table plsport_playsport._wpbillboard_with_vol_3_biweek_1 engine = myisam
SELECT userid, nickname, allianceid, alliancename, dish, vol, wingame, losegame, biweekgame, round((wingame/biweekgame),2) as winratio
FROM plsport_playsport._wpbillboard_with_vol_3_biweek;

# 表a: 第一週注數+第二週注數
create table plsport_playsport._wpbillboard_with_vol_3_first_and_second_week engine = myisam
select a.userid, a.nickname, a.allianceid, a.alliancename, a.dish, a.vol, sum(a.first_week) as first_week, sum(a.second_week) as second_week
from (
  SELECT userid, nickname, allianceid, alliancename, dish, vol, 
       (case when (week_odd=1) then totalgame else 0 end) as first_week,
       (case when (week_odd=2) then totalgame else 0 end) as second_week
  FROM plsport_playsport._wpbillboard_with_vol_3
  order by userid) as a
group by a.userid, a.nickname, a.allianceid, a.alliancename, a.dish, a.vol; #下次SQL可以把a.nickname和a.alliancename移除掉, 因為多餘


create table plsport_playsport._temp1 engine = myisam
SELECT concat(userid,'_',allianceid,'_',dish,'_',vol) as main_id,
       userid, nickname, allianceid, alliancename, dish, vol, first_week, second_week
FROM plsport_playsport._wpbillboard_with_vol_3_first_and_second_week;

    ALTER TABLE plsport_playsport._temp1 ADD INDEX (`main_id`);
    ALTER TABLE plsport_playsport._temp1 convert to character set utf8 collate utf8_general_ci;

create table plsport_playsport._temp2 engine = myisam
SELECT concat(userid,'_',allianceid,'_',dish,'_',vol) as main_id,
       userid, nickname, allianceid, alliancename, dish, vol, wingame, losegame, biweekgame, winratio
FROM plsport_playsport._wpbillboard_with_vol_3_biweek_1;

    ALTER TABLE plsport_playsport._temp2 ADD INDEX (`main_id`);
    ALTER TABLE plsport_playsport._temp2 convert to character set utf8 collate utf8_general_ci;

# 完成第1週+第2週+雙週注數的表
create table plsport_playsport._wpbillboard_with_vol_4 engine = myisam
SELECT a.main_id, a.userid, a.nickname, a.allianceid, a.alliancename, a.dish, a.vol, a.first_week, a.second_week,
       b.biweekgame, b.wingame, b.losegame, b.winratio
FROM plsport_playsport._temp1 a left join plsport_playsport._temp2 b on a.main_id = b.main_id
where a.userid <> 'daniel690505'; # 此使用者有點異常

    # 檢查有無注數異常 (例:-32, -30)
    select a.c, count(main_id)
    from (
      SELECT main_id, first_week+second_week as check_week, biweekgame, ((first_week+second_week) - biweekgame) as c
      FROM plsport_playsport._wpbillboard_with_vol_4) as a
    group by a.c;

# 這次任務要撈的範圍
create table plsport_playsport._wpbillboard_with_vol_5 engine = myisam
SELECT * FROM plsport_playsport._wpbillboard_with_vol_4
where vol > 119 # 7月之後的莊殺期數
and allianceid in (1,2); # MLB, 日棒

create table plsport_playsport._wpbillboard_with_vol_6 engine = myisam
SELECT a.userid, a.nickname, a.allianceid, a.alliancename, a.dish, a.vol, 
       a.first_week, a.second_week, a.biweekgame, a.wingame, a.losegame, a.winratio, b.date_end as predict_date
FROM plsport_playsport._wpbillboard_with_vol_5 a left join plsport_playsport.medal_fire_vols b on a.vol = b.vol;

create table plsport_playsport._wpbillboard_with_vol_7 engine = myisam
SELECT a.userid, a.nickname, a.allianceid, a.alliancename, a.dish, a.vol, 
       a.first_week, a.second_week, a.biweekgame, a.wingame, a.losegame, a.winratio, a.predict_date, date(b.createon) as join_date
FROM plsport_playsport._wpbillboard_with_vol_6 a left join plsport_playsport.member b on a.userid = b.userid;

create table plsport_playsport._wpbillboard_with_vol_8 engine = myisam
SELECT userid, nickname, allianceid, alliancename, dish, vol, 
       first_week, second_week, biweekgame, wingame, losegame, winratio, predict_date, join_date, round(datediff(predict_date,join_date)/30,0) as dif
FROM plsport_playsport._wpbillboard_with_vol_7;

create table plsport_playsport._wpbillboard_with_vol_9 engine = myisam
SELECT userid, nickname, allianceid, alliancename, dish, vol, 
       first_week, second_week, biweekgame, wingame, losegame, winratio, (case when (dif<7) then '6'
                                        when (dif<13) then '12'
                                        when (dif<19) then '18'
                                        when (dif<23) then '24'
                                        when (dif<29) then '30'
                                        when (dif<35) then '36' 
                                        else '37' end) as dif
FROM plsport_playsport._wpbillboard_with_vol_8;

# MLB
    SELECT *
    FROM plsport_playsport._wpbillboard_with_vol_9
    where allianceid = 1 # MLB
    and first_week  >= 9 # 第一週注數
    and second_week >= 9 # 第二週注數
    and biweekgame  >= 28; #雙週注數

    SELECT dish, vol, dif, count(userid) as c 
    FROM plsport_playsport._wpbillboard_with_vol_9
    where allianceid = 1 # MLB
    and first_week  >= 9 # 第一週注數
    and second_week >= 9 # 第二週注數
    and biweekgame  >= 28 #雙週注數
    group by dish, vol, dif;
# 日棒
    SELECT *
    FROM plsport_playsport._wpbillboard_with_vol_9
    where allianceid = 2 # MLB
    and first_week  >= 8 # 第一週注數
    and second_week >= 8 # 第二週注數
    and biweekgame  >= 24; #雙週注數

    SELECT dish, vol, dif, count(userid) as c 
    FROM plsport_playsport._wpbillboard_with_vol_9
    where allianceid = 2 # MLB
    and first_week  >= 8 # 第一週注數
    and second_week >= 8 # 第二週注數
    and biweekgame  >= 24 #雙週注數
    group by dish, vol, dif;

# 開始處理單場殺手的部分
# 要匯入單殺的主推表
#     (1) mainpmpbillboard  運彩盤
#     (2) imainpmpbillboard 國際盤

create table plsport_playsport.singlekiller_record engine = myisam
SELECT userid, nickname, allianceid, alliancename, (case when (allianceid is not null) then 'TWN' else 'error' end) as dish,
       wingame, losegame, (wingame+losegame) as totalgame, winpercentage, yearmonth
FROM plsport_playsport.mainpmpbillboard
where yearmonth in ('201406','201407','201408','201409','201410')
and allianceid in (1,2);

insert ignore into plsport_playsport.singlekiller_record
SELECT userid, nickname, allianceid, alliancename, (case when (allianceid is not null) then 'INT' else 'error' end) as dish,
       wingame, losegame, (wingame+losegame) as totalgame, winpercentage, yearmonth
FROM plsport_playsport.imainpmpbillboard
where yearmonth in ('201406','201407','201408','201409','201410')
and allianceid in (1,2);

create table plsport_playsport.singlekiller_record_1 engine = myisam
select a.userid, a.nickname, a.allianceid, a.alliancename, a.dish, a.wingame, a.losegame, a.totalgame, a.winpercentage, date(concat(y,'-',m,'-','30')) as d
from (
  SELECT userid, nickname, allianceid, alliancename, dish, wingame, losegame, totalgame, winpercentage, substr(yearmonth,1,4) as y, substr(yearmonth,5,2) as m
  FROM plsport_playsport.singlekiller_record) as a;

create table plsport_playsport.singlekiller_record_2 engine = myisam
SELECT a.userid, a.nickname, a.allianceid, a.alliancename, a.dish, a.wingame, a.losegame, a.totalgame, a.winpercentage, a.d, date(b.createon) as join_date
FROM plsport_playsport.singlekiller_record_1 a left join plsport_playsport.member b on a.userid = b.userid;

create table plsport_playsport.singlekiller_record_3 engine = myisam
SELECT userid, nickname, allianceid, alliancename, dish, wingame, losegame, totalgame, winpercentage, d, join_date, round(datediff(d,join_date)/30,0) as dif
FROM plsport_playsport.singlekiller_record_2;

create table plsport_playsport.singlekiller_record_4 engine = myisam
SELECT userid, nickname, allianceid, alliancename, dish, wingame, losegame, totalgame, winpercentage, (case when (dif<7) then '6'
                                                        when (dif<13) then '12'
                                                        when (dif<19) then '18'
                                                        when (dif<23) then '24'
                                                        when (dif<29) then '30'
                                                        when (dif<35) then '36' 
                                                        else '37' end) as dif
FROM plsport_playsport.singlekiller_record_3;

SELECT yearmonth, dish, dif, count(userid) as c
FROM plsport_playsport.singlekiller_record_4
where allianceid = 1 # MLB
and totalgame >= 25  # 符合資格注數
group by yearmonth, dish, dif
order by dish, yearmonth;  

SELECT yearmonth, dish, dif, count(userid) as c
FROM plsport_playsport.singlekiller_record_4
where allianceid = 2 # 日棒
and totalgame >= 20  # 符合資格注數
group by yearmonth, dish, dif
order by dish, yearmonth;  







# ===============================================================================================
#    2013/11/15 edited
#     <找出殺手是在什麼時候成為長期穩定殺手的>
#     可以從_medal_fire_2013這個表來開始研究, 這個表只有2013年的medal_fire資料<錯誤>
#     應該要從_medal_fire來推, 因為長期穩定殺手的資格是永久影響的, 不能只籨2013年來推
#         backtoback:1當期是殺手
#         backtoback:2已經連續2期是殺手
# 
#     執行順序:(1)>(2)>(3)>(4)
# ===============================================================================================

# [A]以下SQL的目的是:
#     (1)可以算出隨著莊殺期數越來越多, 長期穩定在全站人數的變化
#     (2)每一期有多少長期穩定殺手
create table killer.medal_fire engine = myisam select * from plsport_playsport.medal_fire;
create table killer.medal_fire_vols engine = myisam select * from plsport_playsport.medal_fire_vols;

create table killer._medal_fire engine = myisam
SELECT vol, userid, nickname, allianceid, alliancename, mode as gamehost, backtoback 
FROM killer.medal_fire;

# (1)第一位長期穩定殺手產生
create table killer._first_stable_killer engine = myisam
select a.userid, a.nickname, a.allianceid, a.alliancename, a.gamehost, a.b, a.become_stable_killer
from (
    SELECT userid, nickname, allianceid, alliancename, gamehost, count(backtoback) as b, 
           (case when (userid is not null) then 4 end) as become_stable_killer # 在第4期變成長期穩定殺手
    FROM killer._medal_fire
    where vol between 1 and 4 # vol期累計期間
    group by userid, nickname, allianceid, alliancename, gamehost) as a
where a.b=3;

# (2)>>>執行C:\proc\python\calculate\1_calculate_when_killer_became_stable.py
#       記得要調整莊殺的期數範圍, 要打開.py檔修改

# (3)每一期中有那些人是擁有殺手資格的
create table killer._became_stable_killer engine = myisam
select userid, nickname, allianceid, alliancename,
       (case when (gamehost='1') then '運彩'
             when (gamehost='2') then '國際' end) as mode, 
       gamehost, b, become_stable_killer,
       (case when (gamehost is not null) then 'stable_killer_in_vol' end) as been_stable_killer
from killer._first_stable_killer
order by b;
 
# (4)殺手是那一期當上穩定殺手的, 最後的資訊, 排除重覆當上穩定殺手的資訊
create table killer._became_stable_killer_in_vol engine = myisam
select *
from (
       SELECT userid, nickname, allianceid, alliancename, 
         (case when (gamehost='1') then '運彩'
           when (gamehost='2') then '國際' end) as mode, 
        gamehost, b, min(become_stable_killer) as become_stable_killer # 當上的是那一期
       FROM killer._first_stable_killer
       group by userid, nickname, allianceid, alliancename, gamehost, b) as a
order by a.become_stable_killer desc;

    ALTER TABLE  killer._became_stable_killer        CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
    ALTER TABLE  killer._became_stable_killer_in_vol CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
    ALTER TABLE  killer._became_stable_killer        ADD INDEX (userid, become_stable_killer, mode, allianceid);
    ALTER TABLE  killer._became_stable_killer_in_vol ADD INDEX (userid, mode, allianceid);

# killer._became_stable_killer:        每期有那些人是長期穩定殺手
# killer._became_stable_killer_in_vol: 長期穩定殺手是在那一期當上的

# 每一期全站有多少位長期穩定殺手? 為累積的, 期數越後面, 長期穩定的殺手就越來越多
create table killer._stable_killer_at_every_vol engine = myisam
SELECT become_stable_killer as vol, allianceid, alliancename, mode, count(userid) as c
FROM killer._became_stable_killer
group by become_stable_killer, allianceid, alliancename, mode
order by become_stable_killer desc;

            # 完成, 輸出給excel讀
            SELECT 'vol', 'allianceid', 'alliancename', 'mode', 'count'  union (
            SELECT *
            into outfile 'C:/Users/1-7_ASUS/Desktop/_stable_killer_at_every_vol.txt'
            fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
            FROM killer._stable_killer_at_every_vol);


create table killer._medal_fire_with_check_id engine = myisam 
SELECT concat(userid,'_',allianceid,'_',gamehost) as check_id, vol, userid, nickname, allianceid, alliancename, gamehost
FROM killer._medal_fire;

create table killer._became_stable_killer_in_vol_with_check_id engine = myisam 
SELECT concat(userid,'_',allianceid,'_',gamehost) as check_id, 
       userid, nickname, allianceid, alliancename, mode, gamehost, b, become_stable_killer
FROM killer._became_stable_killer_in_vol;

    ALTER TABLE killer._medal_fire_with_check_id                  convert to character set utf8 collate utf8_general_ci;
    ALTER TABLE killer._became_stable_killer_in_vol_with_check_id convert to character set utf8 collate utf8_general_ci;
    ALTER TABLE killer._medal_fire_with_check_id                  ADD INDEX (`check_id`);
    ALTER TABLE killer._became_stable_killer_in_vol_with_check_id ADD INDEX (`check_id`);


create table killer._medal_fire_with_when_they_become_stable_killer engine = myisam
SELECT a.vol, a.userid, a.nickname, a.allianceid, a.alliancename, a.gamehost, b.become_stable_killer
FROM killer._medal_fire_with_check_id a left join killer._became_stable_killer_in_vol_with_check_id b on a.check_id = b.check_id;

create table killer._medal_fire_with_when_they_become_stable_killer_1 engine = myisam
SELECT vol, userid, nickname, allianceid, alliancename, gamehost, become_stable_killer, (vol-become_stable_killer) as n
FROM killer._medal_fire_with_when_they_become_stable_killer;

    # 檢查user: 諸葛狂龍, 結果正確無誤
    SELECT * FROM killer._medal_fire_with_when_they_become_stable_killer_1
    where userid = 'a120869420'
    and allianceid = 2
    order by gamehost, vol;


# 完成!^O^, 正確指出在當期殺手是否為長期穩定?
create table killer._medal_fire_with_when_they_become_stable_killer_2 engine = myisam
SELECT vol, userid, nickname, allianceid, alliancename, gamehost,
       (case when (gamehost=2) then '國際' else '運彩' end) as mode,
       become_stable_killer, n,
       (case when (n>-1) then 1 else 0 end) as n_stable_killer
FROM killer._medal_fire_with_when_they_become_stable_killer_1;

    # 檢查user: 諸葛狂龍, 結果正確無誤
    SELECT * FROM killer._medal_fire_with_when_they_become_stable_killer_2
    where userid = 'a120869420' 
        and allianceid = 2 and gamehost = 2
    order by mode, vol;


create table killer._medal_fire_with_when_they_become_stable_killer_3 engine = myisam
select a.vol, a.alliancename, a.mode, (case when (a.vol is not null) then 'all_killer_count' end) as killer, a.all_killer_count as c
from (
  SELECT vol, alliancename, mode, count(userid) as all_killer_count 
  FROM killer._medal_fire_with_when_they_become_stable_killer_2
  group by vol, alliancename, mode) as a
union
select a.vol, a.alliancename, a.mode, (case when (a.vol is not null) then 'stable_killer_count' end) as killer, a.stable_killer_count as c
from (
  SELECT vol, alliancename, mode, count(userid) as stable_killer_count 
  FROM killer._medal_fire_with_when_they_become_stable_killer_2
    where n_stable_killer = 1
  group by vol, alliancename, mode) as a;

# _medal_fire_with_when_they_become_stable_killer_3 可以匯出給R繪製成圖
SELECT 'vol', 'alliancename', 'mode', 'killer', 'c' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_medal_fire_with_when_they_become_stable_killer_3.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM killer._medal_fire_with_when_they_become_stable_killer_3);

# 以下是為了方便, 計算出佔比
create table killer._medal_fire_with_when_they_become_stable_killer_3_percent engine = myisam
select b.vol, b.alliancename, b.mode, b.all_killer_count, b.stable_killer_count, round((b.stable_killer_count/b.all_killer_count),3) as precent_stable_killers
from (
  select a.vol, a.alliancename, a.mode, sum(a.all_killer_count) as all_killer_count, sum(a.stable_killer_count) as stable_killer_count
  from (
    SELECT vol, alliancename, mode, (case when (killer='all_killer_count') then c else 0 end) as all_killer_count,
                    (case when (killer='stable_killer_count') then c else 0 end) as stable_killer_count
    FROM killer._medal_fire_with_when_they_become_stable_killer_3) as a 
  group by a.vol, a.alliancename, a.mode) as b;

SELECT 'vol', 'alliancename', 'mode', 'all_killer_count', 'stable_killer_count','percent_stable_killer' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_medal_fire_with_when_they_become_stable_killer_3_percent.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM killer._medal_fire_with_when_they_become_stable_killer_3_percent);


# [B]以下SQL的目的是:
#     (1)可以算出隨著莊殺期數越來越多, 長期穩定在全站人數的變化
#     (2)每一期有多少長期穩定殺手
#     ***條件:是計算若套用"近兩年當三次殺手才有長期穩定"，每期各聯盟的長期穩定殺手佔多少比例

create table killer._medal_fire engine = myisam
SELECT vol, userid, nickname, allianceid, alliancename, mode as gamehost, backtoback 
FROM killer.medal_fire;

# (1)第一位長期穩定殺手產生
create table killer._first_stable_killer engine = myisam
select a.userid, a.nickname, a.allianceid, a.alliancename, a.gamehost, a.b, a.become_stable_killer
from (
    SELECT userid, nickname, allianceid, alliancename, gamehost, count(backtoback) as b, 
           (case when (userid is not null) then 4 end) as become_stable_killer # 在第4期變成長期穩定殺手
    FROM killer._medal_fire
    where vol between 1 and 4 # vol期累計期間
    group by userid, nickname, allianceid, alliancename, gamehost) as a
where a.b=3;

# (2)>>>執行C:\proc\python\calculate\1_calculate_when_killer_became_stable_1.py
#       要小心是不一樣的.py檔哦!!!
#       條件是寫近2年內, 但程式裡是寫近52期內, 因為1年有26期, 2年共有52期

# (3)每一期中有那些人是擁有殺手資格的
create table killer._became_stable_killer engine = myisam
select userid, nickname, allianceid, alliancename,
       (case when (gamehost='1') then '運彩'
             when (gamehost='2') then '國際' end) as mode, 
       gamehost, b, become_stable_killer,
       (case when (gamehost is not null) then 'stable_killer_in_vol' end) as been_stable_killer
from killer._first_stable_killer
order by b;

create table killer._medal_fire_with_check_id engine = myisam 
SELECT concat(vol,'_',userid,'_',allianceid,'_',gamehost) as check_id, vol, userid, nickname, allianceid, alliancename, gamehost
FROM killer._medal_fire;

create table killer._became_stable_killer_with_check_id engine = myisam 
SELECT concat(become_stable_killer,'_',userid,'_',allianceid,'_',gamehost) as check_id, 
       userid, nickname, allianceid, alliancename, mode, gamehost, become_stable_killer
FROM killer._became_stable_killer;

    ALTER TABLE killer._medal_fire_with_check_id                  convert to character set utf8 collate utf8_general_ci;
    ALTER TABLE killer._became_stable_killer_with_check_id        convert to character set utf8 collate utf8_general_ci;
    ALTER TABLE killer._medal_fire_with_check_id                  ADD INDEX (`check_id`);
    ALTER TABLE killer._became_stable_killer_with_check_id        ADD INDEX (`check_id`);

create table killer._medal_fire_with_when_they_become_stable_killer engine = myisam
SELECT a.vol, a.userid, a.nickname, a.allianceid, a.alliancename, a.gamehost, b.become_stable_killer
FROM killer._medal_fire_with_check_id a left join killer._became_stable_killer_with_check_id b on a.check_id = b.check_id;

create table killer._medal_fire_with_when_they_become_stable_killer_1 engine = myisam
SELECT vol, userid, nickname, allianceid, alliancename, gamehost, become_stable_killer, (vol-become_stable_killer) as n
FROM killer._medal_fire_with_when_they_become_stable_killer;


SELECT 'vol', 'userid', 'nickname', 'allianceid', 'alliancename', 'gamehost', 'become_stable_killer', 'n' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_medal_fire_with_when_they_become_stable_killer_1.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM killer._medal_fire_with_when_they_become_stable_killer_1);











SELECT * FROM killer._medal_fire_with_when_they_become_stable_killer
where userid = 'Sabathia52' 
and allianceid = 1 
and gamehost = 1;

SELECT * FROM killer._became_stable_killer_with_check_id
where userid = 'a120869420' 
and allianceid = 2 
and gamehost = 1;

SELECT * FROM killer._first_stable_killer
where userid = 'a120869420' 
and allianceid = 2 
and gamehost = 1;

SELECT * FROM killer._medal_fire
where userid = 'a120869420' 
and allianceid = 2 
and gamehost = 1;

select a.userid, a.nickname, a.allianceid, a.alliancename, a.gamehost, a.b, a.become_stable_killer
from (
  SELECT userid, nickname, allianceid, alliancename, gamehost, count(backtoback) as b, 
       (case when (userid is not null) then 62 end) as become_stable_killer
  FROM killer._medal_fire
  where vol between 10 and 62
    and userid = 'a120869420' 
  and allianceid = 2 
  and gamehost = 1
  group by userid, allianceid, gamehost) as a
where a.b=3;



  SELECT userid, nickname, allianceid, alliancename, gamehost, count(backtoback) as b, 
       (case when (userid is not null) then 62 end) as become_stable_killer
  FROM killer._medal_fire
  where vol between 10 and 62
    and userid = 'a120869420' 
  and allianceid = 2 
  and gamehost = 1
  group by userid, allianceid, gamehost;



