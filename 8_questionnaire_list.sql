# 滿意度問券ver4.0 late-2014

create table questionnaire.satisfactionquestionnaire engine = myisam            select * from plsport_playsport.satisfactionquestionnaire; #主要問卷版本
create table questionnaire.satisfactionquestionnaire_answer engine = myisam     select * from plsport_playsport.satisfactionquestionnaire_answer; #問卷的答案
create table questionnaire.satisfactionquestionnaire_memberlist engine = myisam select * from plsport_playsport.satisfactionquestionnaire_memberlist; #名單

use questionnaire;
/*--------------------------------------------
    PART.1 查詢基本問卷的情況
---------------------------------------------*/
/*查看完成問卷的人*/
SELECT * FROM questionnaire.satisfactionquestionnaire_memberlist
where iscompletequestionnaire = '1';

/*查看完成問卷的人數*/
select count(a.iscompletequestionnaire)
from (
    SELECT * FROM questionnaire.satisfactionquestionnaire_memberlist
    where iscompletequestionnaire = '1') as a
group by a.iscompletequestionnaire;

/*查看勾選不要再問我的人*/
SELECT * FROM questionnaire.satisfactionquestionnaire_memberlist
where ischeckedneveraskme = '1';

/*查看是從什麼地方進入問題*/
SELECT entrance, count(entrance) 
FROM questionnaire.satisfactionquestionnaire_answer
group by entrance;

/*平均花費時間*/
SELECT avg(spendminute)
FROM questionnaire.satisfactionquestionnaire_answer
where spendminute>0.4;

/*--------------------------------------------
    PART.2 轉換問券成樞紐的形式
---------------------------------------------*/
# 篩選出ver4.0的, 也就是新版的問券
create table plsport_playsport.satisfactionquestionnaire_answer_ver_4 engine = myisam
SELECT * FROM plsport_playsport.satisfactionquestionnaire_answer
where version = 4.0;

create table plsport_playsport.satisfactionquestionnaire_answer_ver_4_edited engine = myisam
SELECT serialnumber, userid, version, completetime, spendminute, entrance, 
       forum_notused, forum_improve, forum_platform, 
       livescore_notused, livescore_improve, livescore_platform, 
       buyPrediction_notUsed, buyPrediction_improve,
       ourweb, hearaboutus
FROM plsport_playsport.satisfactionquestionnaire_answer_ver_4;

create table plsport_playsport._q_all_answer engine = myisam
SELECT serialnumber, userid, version, completetime, spendminute, entrance, 
       forum_notused, forum_platform,
           (case when (forum_improve like '%0%') then 1 else 0 end) as f0,
           (case when (forum_improve like '%1%') then 1 else 0 end) as f1,
           (case when (forum_improve like '%3%') then 1 else 0 end) as f2,
           (case when (forum_improve like '%5%') then 1 else 0 end) as f3,
           (case when (forum_improve like '%7%') then 1 else 0 end) as f4,
           (case when (forum_improve like '%8%') then 1 else 0 end) as f5,
           (case when (forum_improve like '%9%') then 1 else 0 end) as f6,
           (case when (forum_improve like '%10%') then 1 else 0 end) as f7, 
       livescore_notused, livescore_platform,
           (case when (livescore_improve like '%0%') then 1 else 0 end) as l0,
           (case when (livescore_improve like '%1%') then 1 else 0 end) as l1,
           (case when (livescore_improve like '%5%') then 1 else 0 end) as l2,
           (case when (livescore_improve like '%6%') then 1 else 0 end) as l3,
       buyPrediction_notUsed, 
           (case when (buyPrediction_improve like '%0%') then 1 else 0 end) as p0,
           (case when (buyPrediction_improve like '%2%') then 1 else 0 end) as p1,
           (case when (buyPrediction_improve like '%5%') then 1 else 0 end) as p2,
           (case when (buyPrediction_improve like '%6%') then 1 else 0 end) as p3,
       (case when (ourweb is null) then 'no' end) as 'no_ans',
           (case when (ourweb like '%1-1%') then 1 else 0 end) as '1_1',
           (case when (ourweb like '%1-2%') then 1 else 0 end) as '1_2',
           (case when (ourweb like '%3-1%') then 1 else 0 end) as '3_1',
           (case when (ourweb like '%3-2%') then 1 else 0 end) as '3_2',
           (case when (ourweb like '%5-1%') then 1 else 0 end) as '5_1',
           (case when (ourweb like '%5-2%') then 1 else 0 end) as '5_2',
           (case when (ourweb like '%6-1%') then 1 else 0 end) as '6_1',
           (case when (ourweb like '%6-2%') then 1 else 0 end) as '6_2',
       hearAboutUS
FROM plsport_playsport.satisfactionquestionnaire_answer_ver_4_edited
where userid not in ('yenhsun1982', 'monkey', 'chinginge', 'pauleanr', 'ydasam') # 工友都要排除掉
and spendminute > 0.5; # 小於30秒完成問卷的人就不計

/*--------------------------------------------
    PART.3 [圖表程式化]輸出給R使用
---------------------------------------------*/
# 輸出.csv檔給R使用
select 'serialnumber','forum_notused','forum_platform','f0','f1','f2','f3','f4','f5','f6','f7',
       'livescore_notused','livescore_platform','l0','l1','l2','l3',
       'buyPrediction_notUsed','p0','p1','p2','p3','no_ans','1_1','1_2','3_1','3_2','5_1','5_2','6_1','6_2','hearAboutUS' union (
select  serialnumber,forum_notused,forum_platform,f0,f1,f2,f3,f4,f5,f6,f7,
        livescore_notused,livescore_platform,l0,l1,l2,l3,
        buyPrediction_notUsed,p0,p1,p2,p3,no_ans,1_1,1_2,3_1,3_2,5_1,5_2,6_1,6_2,hearAboutUS
into outfile 'C:/proc/r/web_analysis/questionnaire_ver_4.csv' 
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM plsport_playsport._q_all_answer);

/*--------------------------------------------
    PART.4 撈出意見的回饋,可以看出意見是那位使用者userid給的(這部分已經寫成python自動化, 基本上是用不到part.4)
---------------------------------------------*/
use plsport_playsport;
#----------------------------------------------------------------------------------------------
#先刪掉現有的table
#----------------------------------------------------------------------------------------------
drop table if exists plsport_playsport._q_all_feedback;
drop table if exists plsport_playsport._q_all_feedback_export;

#----------------------------------------------------------------------------------------------
#開始整理
#----------------------------------------------------------------------------------------------
create table plsport_playsport._q_all_feedback engine = myisam
SELECT userid, serialnumber, completetime, forum_other, livescore_other, prediction_other, buypcash_other, buyprediction_other
FROM plsport_playsport.satisfactionquestionnaire_answer
where userid not in ('yenhsun1982', 'monkey', 'chinginge', 'pauleanr', 'ydasam')
and spendminute > 0.5
and version = 4.0;

create table plsport_playsport._q_all_feedback_export engine = myisam
select *
from (
    select a.userid, a.serialnumber, a.completetime, a.forum_other, a.livescore_other, a.prediction_other, a.buypcash_other, a.buyprediction_other, (a.q1+a.q2+a.q3+a.q4+a.q5) as c
    from (
        SELECT userid, serialnumber, completetime, forum_other, livescore_other, prediction_other, buypcash_other, buyprediction_other,
            (case when(forum_other is null) then 1 end) as q1,
            (case when(livescore_other is null) then 1 end) as q2,
            (case when(prediction_other is null) then 1 end) as q3,
            (case when(buypcash_other is null) then 1 end) as q4,
            (case when(buyprediction_other is null) then 1 end) as q5
        FROM plsport_playsport._q_all_feedback) as a)as b
where b.c is null;

ALTER TABLE  `_q_all_feedback_export` CHANGE  `userid`  `userid` VARCHAR( 20 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;


create table plsport_playsport._q_all_feedback_export_1 engine = myisam
SELECT a.userid, b.nickname, a.serialnumber, a.completetime, a.forum_other, a.livescore_other, 
       a.prediction_other, a.buypcash_other, a.buyprediction_other, a.c 
FROM plsport_playsport._q_all_feedback_export a left join plsport_playsport.member b on a.userid = b.userid;

drop table plsport_playsport._q_all_feedback_export;
rename table plsport_playsport._q_all_feedback_export_1 to plsport_playsport._q_all_feedback_export;
ALTER TABLE  `_q_all_feedback_export` CHANGE  `nickname`  `nickname` CHAR( 100 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ;

#----------------------------------------------------------------------------------------------
#對欄位的字串問題做整理, 刪掉奇怪的字串
#----------------------------------------------------------------------------------------------
UPDATE plsport_playsport._q_all_feedback_export set forum_other         = TRIM(forum_other);          #刪掉空白字完
UPDATE plsport_playsport._q_all_feedback_export set livescore_other     = TRIM(livescore_other);      #刪掉空白字完
UPDATE plsport_playsport._q_all_feedback_export set prediction_other    = TRIM(prediction_other);     #刪掉空白字完
UPDATE plsport_playsport._q_all_feedback_export set buypcash_other      = TRIM(buypcash_other);       #刪掉空白字完
UPDATE plsport_playsport._q_all_feedback_export set buyprediction_other = TRIM(buyprediction_other);  #刪掉空白字完
UPDATE plsport_playsport._q_all_feedback_export set nickname            = TRIM(nickname);             #刪掉空白字完

update plsport_playsport._q_all_feedback_export set nickname = replace(nickname, '.',''); 
update plsport_playsport._q_all_feedback_export set nickname = replace(nickname, ';','');
update plsport_playsport._q_all_feedback_export set nickname = replace(nickname, '/','');
update plsport_playsport._q_all_feedback_export set nickname = replace(nickname, '\\','_');
update plsport_playsport._q_all_feedback_export set nickname = replace(nickname, '"','');
update plsport_playsport._q_all_feedback_export set nickname = replace(nickname, '&','');
update plsport_playsport._q_all_feedback_export set nickname = replace(nickname, '#','');
update plsport_playsport._q_all_feedback_export set nickname = replace(nickname, ' ','');

update plsport_playsport._q_all_feedback_export set forum_other = replace(forum_other, '.',''); 
update plsport_playsport._q_all_feedback_export set forum_other = replace(forum_other, ';','');
update plsport_playsport._q_all_feedback_export set forum_other = replace(forum_other, '/','');
update plsport_playsport._q_all_feedback_export set forum_other = replace(forum_other, '\\','_');
update plsport_playsport._q_all_feedback_export set forum_other = replace(forum_other, '"','');
update plsport_playsport._q_all_feedback_export set forum_other = replace(forum_other, '&','');
update plsport_playsport._q_all_feedback_export set forum_other = replace(forum_other, '#','');
update plsport_playsport._q_all_feedback_export set forum_other = replace(forum_other, ' ','');

update plsport_playsport._q_all_feedback_export set livescore_other = replace(livescore_other, '.',''); 
update plsport_playsport._q_all_feedback_export set livescore_other = replace(livescore_other, ';','');
update plsport_playsport._q_all_feedback_export set livescore_other = replace(livescore_other, '/','');
update plsport_playsport._q_all_feedback_export set livescore_other = replace(livescore_other, '\\','_');
update plsport_playsport._q_all_feedback_export set livescore_other = replace(livescore_other, '"','');
update plsport_playsport._q_all_feedback_export set livescore_other = replace(livescore_other, '&','');
update plsport_playsport._q_all_feedback_export set livescore_other = replace(livescore_other, '#','');
update plsport_playsport._q_all_feedback_export set livescore_other = replace(livescore_other, ' ','');

update plsport_playsport._q_all_feedback_export set prediction_other = replace(prediction_other, '.',''); 
update plsport_playsport._q_all_feedback_export set prediction_other = replace(prediction_other, ';','');
update plsport_playsport._q_all_feedback_export set prediction_other = replace(prediction_other, '/','');
update plsport_playsport._q_all_feedback_export set prediction_other = replace(prediction_other, '\\','_');
update plsport_playsport._q_all_feedback_export set prediction_other = replace(prediction_other, '"','');
update plsport_playsport._q_all_feedback_export set prediction_other = replace(prediction_other, '&','');
update plsport_playsport._q_all_feedback_export set prediction_other = replace(prediction_other, '#','');
update plsport_playsport._q_all_feedback_export set prediction_other = replace(prediction_other, ' ','');

update plsport_playsport._q_all_feedback_export set buypcash_other = replace(buypcash_other, '.',''); 
update plsport_playsport._q_all_feedback_export set buypcash_other = replace(buypcash_other, ';','');
update plsport_playsport._q_all_feedback_export set buypcash_other = replace(buypcash_other, '/','');
update plsport_playsport._q_all_feedback_export set buypcash_other = replace(buypcash_other, '\\','_');
update plsport_playsport._q_all_feedback_export set buypcash_other = replace(buypcash_other, '"','');
update plsport_playsport._q_all_feedback_export set buypcash_other = replace(buypcash_other, '&','');
update plsport_playsport._q_all_feedback_export set buypcash_other = replace(buypcash_other, '#','');
update plsport_playsport._q_all_feedback_export set buypcash_other = replace(buypcash_other, ' ','');

update plsport_playsport._q_all_feedback_export set buyprediction_other = replace(buyprediction_other, '.',''); 
update plsport_playsport._q_all_feedback_export set buyprediction_other = replace(buyprediction_other, ';','');
update plsport_playsport._q_all_feedback_export set buyprediction_other = replace(buyprediction_other, '/','');
update plsport_playsport._q_all_feedback_export set buyprediction_other = replace(buyprediction_other, '\\','_');
update plsport_playsport._q_all_feedback_export set buyprediction_other = replace(buyprediction_other, '"','');
update plsport_playsport._q_all_feedback_export set buyprediction_other = replace(buyprediction_other, '&','');
update plsport_playsport._q_all_feedback_export set buyprediction_other = replace(buyprediction_other, '#','');
update plsport_playsport._q_all_feedback_export set buyprediction_other = replace(buyprediction_other, ' ','');

    SELECT ifnull(userid, ""), ifnull(nickname, ""), date(completetime), ifnull(forum_other,"")
    into outfile 'C:/proc/python/data/new_questionnaire_1.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._q_all_feedback_export
    where forum_other is not null
    order by completetime desc;

    SELECT ifnull(userid, ""), ifnull(nickname, ""), date(completetime), ifnull(livescore_other,"")
    into outfile 'C:/proc/python/data/new_questionnaire_2.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._q_all_feedback_export
    where livescore_other is not null
    order by completetime desc;

    SELECT ifnull(userid, ""), ifnull(nickname, ""), date(completetime), ifnull(buyprediction_other,"")
    into outfile 'C:/proc/python/data/new_questionnaire_3.csv' 
    fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
    FROM plsport_playsport._q_all_feedback_export
    where buyprediction_other is not null
    order by completetime desc;

/*--------------------------------------------
    PART.5 產出下月的滿意度問券名單
        需要匯入:
        (1)satisfactionquestionnaire_memberlist
        (2)member_signin_log_archive
        (3)member
---------------------------------------------*/
create table questionnaire.satisfactionquestionnaire engine = myisam            select * from plsport_playsport.satisfactionquestionnaire; #主要問卷版本
create table questionnaire.satisfactionquestionnaire_answer engine = myisam     select * from plsport_playsport.satisfactionquestionnaire_answer; #問卷的答案
create table questionnaire.satisfactionquestionnaire_memberlist engine = myisam select * from plsport_playsport.satisfactionquestionnaire_memberlist; #名單

use questionnaire;
/*--------------------------------------------
  (1)產生已經作過問卷的人的名單
---------------------------------------------*/
create table questionnaire._existed_list engine = myisam
select a.userid, count(a.id) as c
from (
    SELECT id, serialnumber, userid, version, completetime 
    FROM plsport_playsport.satisfactionquestionnaire_answer
    where version = 4.0 #只限做過版本4.0的人
    order by completetime) as a
group by a.userid;

/*--------------------------------------------
  (2)上個月有登入過的人
---------------------------------------------*/
create table questionnaire._signin_list engine = myisam
select a.userid, count(a.userid) as user_count
from (
    SELECT userid, signin_time
    FROM plsport_playsport.member_signin_log_archive
    where date(signin_time) between '2014-11-01' and '2014-11-30') as a /*要指定上個月, 例如3月時, 要寫2/1~2/28*/
group by a.userid;

ALTER TABLE _signin_list ADD INDEX (`userid`); 
ALTER TABLE _existed_list ADD INDEX (`userid`);

/*--------------------------------------------
  排除1:
---------------------------------------------*/
ALTER TABLE questionnaire._existed_list CHANGE `userid` `userid` VARCHAR(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
create table questionnaire._list engine = myisam /*上月份的名單, 但排除掉之前有做過問卷的人*/
SELECT a.userid FROM questionnaire._signin_list a left join questionnaire._existed_list b on a.userid = b.userid
where b.userid is null;/*排除掉*/

/*--------------------------------------------
  排除2:
  要先把"註冊機器人"名單生出來,
  使用8_user_find_the robot_register
---------------------------------------------*/
create table questionnaire._problem_members engine = myisam select * from plsport_playsport._problem_members;
ALTER TABLE  questionnaire._list ADD INDEX (`userid`);
ALTER TABLE  questionnaire._list CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  questionnaire._problem_members ADD INDEX (`userid`);
ALTER TABLE  questionnaire._problem_members CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

create table questionnaire._list1 engine = myisam /*排除掉機器人*/
SELECT a.userid
FROM questionnaire._list a left join plsport_playsport._problem_members b on a.userid = b.userid
where b.userid is null; /*排除掉*/

/*最後只是要mapping上member裡的userid名稱, 問卷名單才匯的進去*/
use questionnaire;
ALTER TABLE questionnaire._list1 ADD INDEX (`userid`);
ALTER TABLE questionnaire._list1 CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

/*--------------------------------------------
    完成名單最後階段
---------------------------------------------*/
create table questionnaire._list_full engine = myisam 
SELECT b.userid # 完成的名單, 使用member資料表的userid, 要不然問卷系統不能判斷大小寫的差異, 此為問券的bug
FROM questionnaire._list1 a left join plsport_playsport.member b on a.userid = b.userid;

# 先排除掉工友(有在定期做滿意度問券的工友們)
delete from questionnaire._list_full where userid = 'ydasam';
delete from questionnaire._list_full where userid = 'monkey';
delete from questionnaire._list_full where userid = 'chinginge';
delete from questionnaire._list_full where userid = 'pauleanr';
delete from questionnaire._list_full where userid = 'yenhsun1982';

create table questionnaire._list_limit_3000 engine = myisam
SELECT * FROM questionnaire._list_full
order by rand() # 隨機抽出3000名受測者
limit 0, 3000;

# 再把工友放進去
insert into questionnaire._list_limit_3000 values ('ydasam'),('monkey'),('chinginge'),('pauleanr'),('yenhsun1982');

#重要, 第一次執行要注意工友是否有2筆????

    # 輸出到桌面
    SELECT userid
    into outfile 'C:/Users/1-7_ASUS/Desktop/questionnaire_list.csv'
    fields terminated by ',' enclosed by '' lines terminated by '\r\n' 
    FROM questionnaire._list_limit_3000; 

# 檢查產生的名單中, 有沒有之前填寫過滿意度的名單
ALTER TABLE  `_list_limit_3000` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  `_existed_list` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
select a.userid from _list_limit_3000 a inner join _existed_list b on a.userid = b.userid;
# select的結果應該是空的