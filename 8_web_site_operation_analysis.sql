# ==================================================================================================== 
#  處理action log
# ==================================================================================================== 

use actionlog;

/*(1)簡化table*/
create table _action_201401 engine = myisam select userid, uri, time from action_201401;
create table _action_201402 engine = myisam select userid, uri, time from action_201402;
create table _action_201403 engine = myisam select userid, uri, time from action_201403;
create table _action_201404 engine = myisam select userid, uri, time from action_201404;
create table _action_201405 engine = myisam select userid, uri, time from action_201405;
create table _action_201406 engine = myisam select userid, uri, time from action_201406;
create table _action_201407 engine = myisam select userid, uri, time from action_201407;
create table _action_201408 engine = myisam select userid, uri, time from action_201408;
create table _action_201409 engine = myisam select userid, uri, time from action_201409;
create table _action_201410 engine = myisam select userid, uri, time from action_201410;

/*(2)計算每個月的登入人數, 排除重覆的人*/
create table __action_201401_usercount engine = myisam
select userid, count(uri) as log_count, month(time) as log_month from _action_201401 group by userid;
create table __action_201402_usercount engine = myisam
select userid, count(uri) as log_count, month(time) as log_month from _action_201402 group by userid;
create table __action_201403_usercount engine = myisam
select userid, count(uri) as log_count, month(time) as log_month from _action_201403 group by userid;
create table __action_201404_usercount engine = myisam
select userid, count(uri) as log_count, month(time) as log_month from _action_201404 group by userid;
create table __action_201405_usercount engine = myisam
select userid, count(uri) as log_count, month(time) as log_month from _action_201405 group by userid;
create table __action_201406_usercount engine = myisam
select userid, count(uri) as log_count, month(time) as log_month from _action_201406 group by userid;
create table __action_201407_usercount engine = myisam
select userid, count(uri) as log_count, month(time) as log_month from _action_201407 group by userid;
create table __action_201408_usercount engine = myisam
select userid, count(uri) as log_count, month(time) as log_month from _action_201408 group by userid;
create table __action_201409_usercount engine = myisam
select userid, count(uri) as log_count, month(time) as log_month from _action_201409 group by userid;
create table __action_201410_usercount engine = myisam
select userid, count(uri) as log_count, month(time) as log_month from _action_201410 group by userid;
-- note: 算完就可以drop, 要不然很佔空間

-- 2014/1/2新增, 排除異常名單, 機器人
ALTER TABLE  actionlog.__action_201401_usercount CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  actionlog.__action_201402_usercount CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  actionlog.__action_201403_usercount CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  actionlog.__action_201404_usercount CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  actionlog.__action_201405_usercount CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  actionlog.__action_201406_usercount CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  actionlog.__action_201407_usercount CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  actionlog.__action_201408_usercount CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  actionlog.__action_201409_usercount CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  actionlog.__action_201410_usercount CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
-- 先執行 8_user_find_the robot_register

ALTER TABLE  plsport_playsport._problem_members CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

select count(a.userid) from actionlog.__action_201401_usercount a left join plsport_playsport._problem_members b on a.userid = b.userid where b.userid is null;
select count(a.userid) from actionlog.__action_201402_usercount a left join plsport_playsport._problem_members b on a.userid = b.userid where b.userid is null;
select count(a.userid) from actionlog.__action_201403_usercount a left join plsport_playsport._problem_members b on a.userid = b.userid where b.userid is null;
select count(a.userid) from actionlog.__action_201404_usercount a left join plsport_playsport._problem_members b on a.userid = b.userid where b.userid is null;
select count(a.userid) from actionlog.__action_201405_usercount a left join plsport_playsport._problem_members b on a.userid = b.userid where b.userid is null;
select count(a.userid) from actionlog.__action_201406_usercount a left join plsport_playsport._problem_members b on a.userid = b.userid where b.userid is null;
select count(a.userid) from actionlog.__action_201407_usercount a left join plsport_playsport._problem_members b on a.userid = b.userid where b.userid is null;
select count(a.userid) from actionlog.__action_201408_usercount a left join plsport_playsport._problem_members b on a.userid = b.userid where b.userid is null;
select count(a.userid) from actionlog.__action_201409_usercount a left join plsport_playsport._problem_members b on a.userid = b.userid where b.userid is null;
select count(a.userid) from actionlog.__action_201410_usercount a left join plsport_playsport._problem_members b on a.userid = b.userid where b.userid is null;
-- ======================================================================================
--  準備其它資料表
--  (1)forum
--  (2)forumcontent
--  (3)order_data
--  (4)pcash_log
--  (5)prediction_archive
--      (如果要捉35天前的預測, 那就要捉archive,如果是近期, 捉prediction就可以
--       所以最好每月個5日前就要捉)
-- ======================================================================================

-- ======================================================================================
--  處理討論區
--  固定的檔案:
--   (1)forumcontent_2012    (固定,不要刪)
--   (2)forumcontent_201301  (固定,不要刪)
--   (3)forumcontent_201302_ (未來只需要更新這個就好)
-- ======================================================================================
use forum;

drop table if exists forum.forum;
drop table if exists forum.forum_edited;
drop table if exists forum.forumcontent_edited_reply;
drop table if exists forum.forum_edited_export;
drop table if exists forum.forumcontent;
drop table if exists forum.forum_edited_export_1;

create table forum.forum engine = myisam /*直接把匯入的移到forum裡*/
select * from plsport_playsport.forum
where date(posttime) between '2012-01-01' and '2014-11-30'
and postuser not like '%xiaojita%'; # 2014-11-13洗版po文機器人

drop table if exists forum_temp.forumcontent_2014_;
drop table if exists forum_temp.forumcontent;

create table forum_temp.forumcontent_2014_ engine = myisam /*dump這個比較久, 只有這個是新的*/
select * from plsport_playsport.forumcontent
where date(postdate) between '2014-01-01' and '2014-11-30';

create table forum.forumcontent engine = myisam /*重新merge這2年內的forumcontent, 只更新最近的, 再把3個檔merge起來*/
select * from forum_temp.forumcontent_2012;
insert ignore into forum.forumcontent select * from forum_temp.forumcontent_2013;
insert ignore into forum.forumcontent select * from forum_temp.forumcontent_2014_;

/*主要討論區主版*/
create table plsport_playsport._alliance engine = myisam
SELECT allianceid, alliancename as board, 
       (case when (allianceid = 1) then '棒球'
             when (allianceid = 2) then '棒球'
             when (allianceid = 3) then '籃球'
             when (allianceid = 4) then '其它'
             when (allianceid = 5) then '其它'
             when (allianceid = 6) then '棒球'
             when (allianceid = 7) then '籃球'
             when (allianceid = 8) then '棒球'
             when (allianceid = 9) then '棒球'
             when (allianceid = 21) then '其它'
             when (allianceid = 85) then '其它'
             when (allianceid = 86) then '籃球'
             when (allianceid = 87) then '其它'
             when (allianceid = 88) then '棒球'
             when (allianceid = 89) then '籃球'
             when (allianceid = 90) then '其它'
             when (allianceid = 91) then '其它'
             when (allianceid = 92) then '籃球'
             when (allianceid = 93) then '其它'
             when (allianceid = 94) then '籃球'
             when (allianceid = 95) then '其它'
             when (allianceid = 96) then '其它'
             when (allianceid = 97) then '籃球'
             when (allianceid = 98) then '其它'
             when (allianceid = 99) then '其它'
             when (allianceid = 100) then '其它'
             when (allianceid = 101) then '其它'
             when (allianceid = 102) then '其它'
             when (allianceid = 103) then '籃球'
             when (allianceid = 105) then '其它'
             when (allianceid = 106) then '棒球'
             when (allianceid = 108) then '籃球'
             when (allianceid = 109) then '棒球'
             when (allianceid = 110) then '籃球'
             when (allianceid = 111) then '其它'
             when (allianceid = 112) then '其它'
             when (allianceid = 113) then '其它'
             when (allianceid = 114) then '棒球' else '不清楚'end ) as boardtype
FROM plsport_playsport.alliance
order by allianceid;

/*(1)處理forum*/
/*(1-1)整理後的forum, forum討論區主文*/
use forum;
create table forum_edited engine = myisam
select a.subjectid, a.subject, a.allianceid, a.viewtimes, a.postuser, a.posttime, 
       substr(a.posttime,1,7) as postmonth, substr(a.posttime,1,10) as postday, 
       year(a.posttime) as postyear, month(a.posttime) as postmonth1,
       a.replycount, a.pushcount, b.board, b.boardtype
from forum.forum a left join plsport_playsport._alliance b on a.allianceid = b.allianceid
where b.board is not null
order by a.posttime desc;

/*(2)處理forumcontent:是討論區每篇文章的內容, 包含主文和回文*/
/*(2-1)整理後的forumcontent, forum討論區主文*/
create table forum.forumcontent_edited_reply engine = myisam
select subjectid, userid, postdate, contenttype ,substr(postdate,1,7) as postmonth, substr(postdate,1,10) as postday
from forum.forumcontent
where contenttype = 1;/*回文*/

/*計算發文/回文/推文的次數 by月份*/
select postmonth, count(subjectid) as newPostCount, sum(replyCount) as replyCount, sum(pushcount) as pushCount
from forum.forum_edited
group by postmonth;

/*計算發文人數*/
select a.postmonth, count(a.postuser) as post_users_count
from (
      select postuser, postmonth, count(subjectid) as post_time
      from forum.forum_edited
      group by postuser, postmonth) as a
group by a.postmonth;

/*計算回文人數*/
select a.postmonth, count(a.userid) as reply_users_count
from (
      select userid, postmonth, count(userid) as reply_time
      from forum.forumcontent_edited_reply
      group by userid, postmonth ) as a
group by a.postmonth;


/*用來輸出用的, 各看版和聯盟發文數的統計*/
create table forum.forum_edited_export engine = myisam
select subjectid, postuser, postmonth, postday, postyear, postmonth1, replycount, pushcount, board, boardtype
from forum.forum_edited;

create table forum.forum_edited_export_1 engine = myisam
SELECT postyear as y, postmonth1 as m, board, boardtype, count(subjectid) as p 
FROM forum.forum_edited_export
group by postyear, postmonth1, board, boardtype;

        /*直接輸出至txt檔給R使用*/ 
        select 'year', 'month', 'board', 'boardtype', 'post' union(
        select *
        into outfile 'C:/proc/r/web_analysis/forum_detail.csv' /*記得要改月份*/
        fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
        from forum.forum_edited_export_1)/*記得要改月份*/;




-- ======================================================================================
--  處理預測
    
--  新匯進來的prediction都要改名稱

--  方法1. (還是很慢, 因為host反應慢)
--      在phpMyAdmin中使用的查詢指令, 用id來篩選會快很多, 再匯出成SQL, 一個月大概200萬筆預測記錄
--      SELECT id, userid, nickname, gameid, allianceid, gametype, predict, winner, createon 
--      FROM plsport_playsport.prediction_archive
--      where id >71000000  
--      order by id;

--  方法2. 直接匯出prediction就好了, 記得要在月初5日前匯, 要不然會備份至archive就很麻煩
--      create table prediction.prediction_201312 engine = myisam
--      SELECT * FROM plsport_playsport.prediction
--      where date(createon) between '2013-12-01' and '2013-12-31';
-- ======================================================================================
use prediction;

create table prediction.prediction_201411 engine = myisam
SELECT * FROM plsport_playsport.prediction
where date(createon) between '2014-11-01' and '2014-11-30';

create table p_201401 engine = myisam
select userid, gameid, allianceid, gametype, createon, substr(createon,1,7) as createMonth, substr(createon,1,10) as createDay from prediction_201401;
create table p_201402 engine = myisam
select userid, gameid, allianceid, gametype, createon, substr(createon,1,7) as createMonth, substr(createon,1,10) as createDay from prediction_201402;
create table p_201403 engine = myisam
select userid, gameid, allianceid, gametype, createon, substr(createon,1,7) as createMonth, substr(createon,1,10) as createDay from prediction_201403;
create table p_201404 engine = myisam
select userid, gameid, allianceid, gametype, createon, substr(createon,1,7) as createMonth, substr(createon,1,10) as createDay from prediction_201404;
create table p_201405 engine = myisam
select userid, gameid, allianceid, gametype, createon, substr(createon,1,7) as createMonth, substr(createon,1,10) as createDay from prediction_201405;
create table p_201406 engine = myisam
select userid, gameid, allianceid, gametype, createon, substr(createon,1,7) as createMonth, substr(createon,1,10) as createDay from prediction_201406;
create table p_201407 engine = myisam
select userid, gameid, allianceid, gametype, createon, substr(createon,1,7) as createMonth, substr(createon,1,10) as createDay from prediction_201407;
create table p_201408 engine = myisam
select userid, gameid, allianceid, gametype, createon, substr(createon,1,7) as createMonth, substr(createon,1,10) as createDay from prediction_201408;
create table p_201409 engine = myisam
select userid, gameid, allianceid, gametype, createon, substr(createon,1,7) as createMonth, substr(createon,1,10) as createDay from prediction_201409;
create table p_201410 engine = myisam
select userid, gameid, allianceid, gametype, createon, substr(createon,1,7) as createMonth, substr(createon,1,10) as createDay from prediction_201410;
create table p_201411 engine = myisam
select userid, gameid, allianceid, gametype, createon, substr(createon,1,7) as createMonth, substr(createon,1,10) as createDay from prediction_201411;

        /*====使用者分群專用的====*/
        create table prediction.p_recently engine = myisam select * from prediction.p_201405; /*近4個月預測資料, 看使用者分群要篩至多久前的記錄*/
        insert ignore into prediction.p_recently select * from prediction.p_201406;
        insert ignore into prediction.p_recently select * from prediction.p_201407;
        insert ignore into prediction.p_recently select * from prediction.p_201408;
        insert ignore into prediction.p_recently select * from prediction.p_201409;

                    create table prediction.p_2013 engine = myisam select * from prediction.p_201301;
                    insert ignore into prediction.p_2013 select * from prediction.p_201302;
                    insert ignore into prediction.p_2013 select * from prediction.p_201303;
                    insert ignore into prediction.p_2013 select * from prediction.p_201304;
                    insert ignore into prediction.p_2013 select * from prediction.p_201305;
                    insert ignore into prediction.p_2013 select * from prediction.p_201306;
                    insert ignore into prediction.p_2013 select * from prediction.p_201307;
                    insert ignore into prediction.p_2013 select * from prediction.p_201308;
                    insert ignore into prediction.p_2013 select * from prediction.p_201309;
                    insert ignore into prediction.p_2013 select * from prediction.p_201310;
                    insert ignore into prediction.p_2013 select * from prediction.p_201311;
                    insert ignore into prediction.p_2013 select * from prediction.p_201312;

                    create table prediction.p_2014 engine = myisam select * from prediction.p_201401;
                    insert ignore into prediction.p_2014 select * from prediction.p_201402;
                    insert ignore into prediction.p_2014 select * from prediction.p_201403;
                    insert ignore into prediction.p_2014 select * from prediction.p_201404;
                    insert ignore into prediction.p_2014 select * from prediction.p_201405;
                    insert ignore into prediction.p_2014 select * from prediction.p_201406;
                    insert ignore into prediction.p_2014 select * from prediction.p_201407;
                    insert ignore into prediction.p_2014 select * from prediction.p_201408;
                    insert ignore into prediction.p_2014 select * from prediction.p_201409;
                    insert ignore into prediction.p_2014 select * from prediction.p_201410;
                    insert ignore into prediction.p_2014 select * from prediction.p_201411;

create table prediction.p_main engine = myisam select * from prediction.p_2012;
insert ignore into prediction.p_main select * from prediction.p_2013;
insert ignore into prediction.p_main select * from prediction.p_2014;

                create table prediction.p_main_edited engine = myisam
                SELECT userid, gameid, allianceid, 
						(case when (allianceid=1) then  'MLB' /*只分出主要熱門聯盟*/
							  when (allianceid=2) then  '日棒'
							  when (allianceid=3) then  'NBA'
							  when (allianceid=4) then  '足球'
							  when (allianceid=6) then  '中華職棒'
							  when (allianceid=9) then  '韓棒'
							  when (allianceid=91) then 'NHL'
							  when (allianceid=92) then '韓籃'
							  when (allianceid=97) then '日籃'
							  else '其它' end) as alliance, gametype, createon, createMonth, createDay
                FROM prediction.p_main;

                create table prediction.p_main_edited_1 engine = myisam
                SELECT userid, createMonth as m, allianceid, alliance, count(userid) as user_count
                FROM prediction.p_main_edited
                group by allianceid, createMonth, userid;

                drop table prediction.p_main, prediction.p_main_edited; 
                rename table prediction.p_main_edited_1 to prediction.p_main;

                /*各聯盟預測人數*/
                SELECT createMonth, allianceid, count(userid) as user_count
                FROM prediction.p_main
                group by createMonth, allianceid;

/*每月預測人數*/
select a.createMonth, count(a.userid) as u
from (
    SELECT createMonth, userid, sum(userid) as p
    FROM prediction.p_main
    group by createMonth, userid) as a
group by a.createMonth;


        /*直接輸出至txt檔給R使用*/ 
        /*計算各聯盟的預測數,每月分開, 需要1個月1個月改*/
        select 'userid', 'allianceid', 'alliance' union(
        select userid, allianceid, alliance
        into outfile 'C:/Users/1-7_ASUS/Documents/R/website_monitor/prediction07.txt' /*記得要改月份*/
        fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
        from prediction_201307_count_by_alliance)/*記得要改月份*/;


# 2014-10-08: 每個月每個人預測的天數 (預計)

create table prediction.d_201401 engine = myisam select a.userid, createmonth, count(a.createday) as predict_count
from ( SELECT userid, createday, createmonth, count(gameid) as c FROM prediction.p_201401 group by userid, createday) as a group by a.userid;
create table prediction.d_201402 engine = myisam select a.userid, createmonth, count(a.createday) as predict_count
from ( SELECT userid, createday, createmonth, count(gameid) as c FROM prediction.p_201402 group by userid, createday) as a group by a.userid;
create table prediction.d_201403 engine = myisam select a.userid, createmonth, count(a.createday) as predict_count
from ( SELECT userid, createday, createmonth, count(gameid) as c FROM prediction.p_201403 group by userid, createday) as a group by a.userid;
create table prediction.d_201404 engine = myisam select a.userid, createmonth, count(a.createday) as predict_count
from ( SELECT userid, createday, createmonth, count(gameid) as c FROM prediction.p_201404 group by userid, createday) as a group by a.userid;
create table prediction.d_201405 engine = myisam select a.userid, createmonth, count(a.createday) as predict_count
from ( SELECT userid, createday, createmonth, count(gameid) as c FROM prediction.p_201405 group by userid, createday) as a group by a.userid;
create table prediction.d_201406 engine = myisam select a.userid, createmonth, count(a.createday) as predict_count
from ( SELECT userid, createday, createmonth, count(gameid) as c FROM prediction.p_201406 group by userid, createday) as a group by a.userid;
create table prediction.d_201407 engine = myisam select a.userid, createmonth, count(a.createday) as predict_count
from ( SELECT userid, createday, createmonth, count(gameid) as c FROM prediction.p_201407 group by userid, createday) as a group by a.userid;
create table prediction.d_201408 engine = myisam select a.userid, createmonth, count(a.createday) as predict_count
from ( SELECT userid, createday, createmonth, count(gameid) as c FROM prediction.p_201408 group by userid, createday) as a group by a.userid;
create table prediction.d_201409 engine = myisam select a.userid, createmonth, count(a.createday) as predict_count
from ( SELECT userid, createday, createmonth, count(gameid) as c FROM prediction.p_201409 group by userid, createday) as a group by a.userid;

create table prediction.daily_prediction_2014 engine = myisam
select * from prediction.d_201401;
insert ignore into prediction.daily_prediction_2014 select * from prediction.d_201402;
insert ignore into prediction.daily_prediction_2014 select * from prediction.d_201403;
insert ignore into prediction.daily_prediction_2014 select * from prediction.d_201404;
insert ignore into prediction.daily_prediction_2014 select * from prediction.d_201405;
insert ignore into prediction.daily_prediction_2014 select * from prediction.d_201406;
insert ignore into prediction.daily_prediction_2014 select * from prediction.d_201407;
insert ignore into prediction.daily_prediction_2014 select * from prediction.d_201408;
insert ignore into prediction.daily_prediction_2014 select * from prediction.d_201409;

create table prediction.daily_prediction engine = myisam select * from prediction.daily_prediction_2013;
insert ignore into prediction.daily_prediction select * from prediction.daily_prediction_2014;

# 每個月點n天預測的人有多少人?
select a.createmonth, count(a.userid) as user_count_with_15_predicts
from (
    SELECT userid, createmonth, predict_count 
    FROM prediction.daily_prediction
    where predict_count > 13) as a # 更改數字n天
group by a.createmonth;



-- ======================================================================================
--  處理收益相關的報表
    
-- ======================================================================================
create table revenue.pcash_log      engine = myisam select * from plsport_playsport.pcash_log;
create table revenue.order_data     engine = myisam select * from plsport_playsport.order_data;
create table revenue.predict_seller engine = myisam select * from plsport_playsport.predict_seller;
create table revenue.alliance       engine = myisam select * from plsport_playsport.alliance;

use revenue;
# -------------------------------------------------
# 購買預測
# -------------------------------------------------

/*處理pcash_log, 會員購買預測的相關資訊*/
create table _pcash_log engine = myisam
select userid, amount, date(date) as c_date, month(date) as c_month, year(date) as c_year, substr(date,1,7) as ym, id_this_type
from pcash_log
where payed = 1 and type = 1
and date between '2012-01-01 00:00:00' and '2014-11-30 23:59:59';

/*計算每人每月的累積購買預測金額*/
create table _pcash_log_calculate engine = myisam
select userid, ym, sum(amount) as spent
from _pcash_log
group by userid, ym;

/*query每個月的購買預測pcash金額*/
SELECT ym, year(c_date) as y, c_month as m, sum(amount) as revenue_pcash
FROM revenue._pcash_log
group by ym;

         /*[圖表程式化]輸出給R使用*/
         select 'ym', 'y', 'm', 'revenue_pcash' union(
         select ym, year(c_date) as y, c_month as m, sum(amount) as revenue_pcash
         into outfile 'C:/proc/r/web_analysis/pcash_log.csv' /*記得要改月份*/
         fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
         from revenue._pcash_log group by ym); 

        /*query計算每月有消費的會員*/
        select ym, count(userid) as user_count
        from _pcash_log_calculate
        group by ym;

                -- /*處理order_data*/ 這裡是舊的order data數據
                -- create table _order_data engine = myisam
                -- SELECT userid, createon, substr(createon,1,10) as d, year(createon) as y, month(createon) as m1, substr(createon,1,7) as m, ordernumber, price, payway, sellconfirm
                -- FROM revenue.order_data
                -- where createon between '2012-01-01 00:00:00' and '2014-05-31 23:59:59'
                -- and payway <> 7
                -- and sellconfirm = 1;

                -- /*每個月的儲值噱幣金額*/
                -- SELECT m, y, m1, sum(price) as spent
                -- FROM revenue._order_data
                -- group by m;

                --       /*[圖表程式化]輸出給R使用*/
                --       select 'ym', 'y', 'm', 'revenue_order_data' union(
                --       SELECT m, y, m1, sum(price) as spent
                --       into outfile 'C:/proc/r/web_analysis/order_data.csv' /*記得要改月份*/
                --       fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
                --       FROM revenue._order_data group by m); 

# -------------------------------------------------
# 儲值噱幣 (NEW!! 改成從pcash_log的數據來撈)
# -------------------------------------------------

create table _order_data engine = myisam
SELECT userid, amount as redeem, date, substr(date,1,7) as ym, year(date) as y, substr(date,6,2) as m 
FROM pcash_log
where payed = 1 and type in (3,4)
and date between '2012-01-01 00:00:00' and '2014-11-30 23:59:59';

# 計算每個月有多少人儲值
select a.ym, count(a.userid) as c
from (
    SELECT ym, userid, sum(redeem) as redeem 
    FROM revenue._order_data
    group by ym, userid) as a
group by a.ym;

        /*[圖表程式化]輸出給R使用*/
        select 'ym', 'y', 'm', 'redeem' union(
        SELECT ym, y, m, sum(redeem) as redeem
        into outfile 'C:/proc/r/web_analysis/order_data.csv'
        fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
        FROM revenue._order_data
        group by ym);



# -------------------------------------------------
# Updated: 2014/2/21 更詳細的收益(依聯盟/殺手)
# -------------------------------------------------
use revenue;
create table revenue._predict_seller_with_medal engine = myisam
SELECT id, sellerid, mode, sale_allianceid, sale_gameid, sale_date, substr(sale_date,1,7) as m, substr(sale_date,1,10) as d, sale_price, buyer_count, rank, rank_sk, selltype,
       (case when (selltype = 1) then '莊殺'
             when (selltype = 2) then '單殺'
             when (selltype = 3) then '雙殺' end ) as killtype,
       (case when (rank <11 and selltype = 1) then '金牌'
             when (rank <31 and selltype = 1) then '銀牌'
             when (rank <52 and selltype = 1) then '銅牌'
             when (rank_sk< 11 and selltype = 2) then '金牌'
             when (rank_sk< 31 and selltype = 2) then '銀牌'
             when (rank_sk< 52 and selltype = 2) then '銅牌'
             when (rank < 11 and selltype = 3) then '金牌'
             when (rank_sk < 11 and selltype = 3) then '金牌' else '銀牌' end) as killmedal     
FROM revenue.predict_seller /*最好是指定精確的日期區間*/
where sale_date between '2011-12-15 00:00:00' and '2014-10-31 23:59:59';

create table revenue._alliance engine = myisam
SELECT allianceid, alliancename
FROM revenue.alliance;

ALTER TABLE  _pcash_log ADD INDEX (`id_this_type`);       /*index*/
ALTER TABLE  _predict_seller_with_medal ADD INDEX (`id`); /*index*/
ALTER TABLE  _alliance ADD INDEX (`allianceid`);          /*index*/

create table _pcash_log_with_detailed_info engine = myisam
select c.userid, c.amount, c.c_date, c.c_month, c.c_year, c.ym,
       c.id, c.sellerid, c.sale_allianceid, d.alliancename, c.sale_date, c.sale_price, c.killtype, c.killmedal
from (
    SELECT a.userid, a.amount, a.c_date, a.c_month, a.c_year, a.ym, 
           b.id, b.sellerid, b.sale_allianceid, b.sale_date, b.sale_price, b.killtype, b.killmedal
    FROM revenue._pcash_log a left join revenue._predict_seller_with_medal b on a.id_this_type = b.id) as c
left join _alliance as d on c.sale_allianceid = d.allianceid;

create table _pcash_log_with_detailed_info_ok engine = myisam
SELECT ym, c_year, c_month, alliancename, sale_price, killtype, killmedal, sum(amount) as revenue
FROM revenue._pcash_log_with_detailed_info
group by ym, alliancename, sale_price, killtype, killmedal;

# ALTER TABLE  `_pcash_log_with_detailed_info_ok` CHANGE  `killtype`  `killtype`   VARCHAR( 2 ) CHARACTER SET big5 COLLATE big5_chinese_ci NULL DEFAULT NULL ;
# ALTER TABLE  `_pcash_log_with_detailed_info_ok` CHANGE  `killmedal`  `killmedal` VARCHAR( 2 ) CHARACTER SET big5 COLLATE big5_chinese_ci NULL DEFAULT NULL ;

        /*[圖表程式化]輸出給R使用*/
         select 'ym', 'y', 'm', 'alliance', 'price', 'killtype', 'killmedal', 'revenue' union(
         SELECT ym, c_year, c_month, alliancename, sale_price, killtype, killmedal, revenue
         into outfile 'C:/proc/r/web_analysis/pcash_log_detail.csv' /*記得要改月份*/
         fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
         FROM revenue._pcash_log_with_detailed_info_ok); 


# ======================================================================================
#    ARPU付費會員平均消費金額 - (套用分群版)
#    每個月總儲值金額/付費會員人數=ARPU
#
#    要先將R匯出的csv檔匯入至user_cluster, 檔案是_from_r
# ======================================================================================
use revenue;
create table revenue._from_r engine = myisam select * from user_cluster._from_r;
create table revenue._member engine = myisam select * from user_cluster._member;

create table revenue._redeem_amount_within_31_days engine = myisam
select a.userid, sum(a.price) as redeem_amount
from (
    SELECT userid, price 
    FROM revenue._order_data    
    where createon between subdate(now(),90) and now()) as a
group by a.userid;

ALTER TABLE revenue._from_r ADD INDEX (`id`);
ALTER TABLE revenue._member ADD INDEX (`id`);

create table revenue._from_r_with_real_userid engine = myisam
SELECT a.id, b.userid, a.g 
FROM revenue._from_r a left join revenue._member b on a.id = b.id;

ALTER TABLE revenue._from_r_with_real_userid ADD INDEX (`userid`);
ALTER TABLE revenue._redeem_amount_within_31_days ADD INDEX (`userid`);

create table revenue._redeem_amount_with_cluster engine = myisam
SELECT a.userid, b.g, a.redeem_amount
FROM revenue._redeem_amount_within_31_days a left join revenue._from_r_with_real_userid b on a.userid = b.userid
where b.g is not null;

SELECT g, sum(redeem_amount) as total, count(userid) as user_count
FROM revenue._redeem_amount_with_cluster
group by g;


# ======================================================================================
#    
#    AARRR
#
# ======================================================================================

select a.m, count(a.userid) as c
from (
    SELECT a.userid, substr(a.createon,1,7) as m 
    FROM plsport_playsport.member a left join plsport_playsport._problem_members b on a.userid = b.userid
    where b.userid is null) as a
group by a.m;


# ======================================================================================
#    2014/3/6 柔雅開的任務
#    D2,D3最近3個月有買過預測的人,電話有多少
#
# ======================================================================================

use revenue;
create table revenue._spent_amount_within_90_days engine = myisam /*最近90天(3個月內)有購買預測的人*/
select a.userid, sum(a.amount) as total_spent
from (
    SELECT * 
    FROM revenue._pcash_log
    where c_date between subdate(now(),90) and now()
    order by c_date) as a
group by a.userid;

ALTER TABLE revenue._from_r_with_real_userid ADD INDEX (`userid`);
ALTER TABLE revenue._spent_amount_within_90_days ADD INDEX (`userid`);

create table revenue._from_r_with_real_userid_with_spent engine = myisam
SELECT a.userid, a.g, b.total_spent 
FROM revenue._from_r_with_real_userid a left join revenue._spent_amount_within_90_days b on a.userid = b.userid
where b.total_spent is not null;

create table revenue._order_data_phone engine = myisam
SELECT userid, name, phone, max(createon) as d, count(userid) as c
FROM revenue.order_data
where sellconfirm = 1 and name <> ' '
group by userid, name ;

ALTER TABLE revenue._from_r_with_real_userid_with_spent ADD INDEX (`userid`);
ALTER TABLE revenue._order_data_phone ADD INDEX (`userid`);

create table revenue._from_r_with_real_userid_with_spent_ok engine = myisam
SELECT a.userid, b.name, a.g, a.total_spent, b.phone 
FROM revenue._from_r_with_real_userid_with_spent a left join revenue._order_data_phone b on a.userid = b.userid;

update revenue._from_r_with_real_userid_with_spent_ok set name = replace(name, '&','');
update revenue._from_r_with_real_userid_with_spent_ok set name = replace(name, '#','');
update revenue._from_r_with_real_userid_with_spent_ok set name = replace(name, ';','');
update revenue._from_r_with_real_userid_with_spent_ok set name = replace(name, ' ','');

select 'userid', 'name', 'group', 'total_spent', 'phone' union(
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/text_message_campaign_201403.csv' 
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM revenue._from_r_with_real_userid_with_spent_ok);


# 2014/6/6 action_log計算每個log的平台的次數(造訪裝置的佔比)
create table actionlog.action_201312_platform_type
SELECT platform_type, count(id) as c FROM actionlog.action_201312 group by platform_type;
create table actionlog.action_201401_platform_type
SELECT platform_type, count(id) as c FROM actionlog.action_201401 group by platform_type;
create table actionlog.action_201402_platform_type
SELECT platform_type, count(id) as c FROM actionlog.action_201402 group by platform_type;
create table actionlog.action_201403_platform_type
SELECT platform_type, count(id) as c FROM actionlog.action_201403 group by platform_type;
create table actionlog.action_201404_platform_type
SELECT platform_type, count(id) as c FROM actionlog.action_201404 group by platform_type;
create table actionlog.action_201405_platform_type
SELECT platform_type, count(id) as c FROM actionlog.action_201405 group by platform_type;