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

# 2016-06已上了新版的問券(6.0)
drop table if exists plsport_playsport.satisfactionquestionnaire_answer_ver_5;
create table plsport_playsport.satisfactionquestionnaire_answer_ver_5 engine = myisam
SELECT * FROM plsport_playsport.satisfactionquestionnaire_answer
where version in ('5.0','6.0');

drop table if exists plsport_playsport.satisfactionquestionnaire_answer_ver_5_edited;
create table plsport_playsport.satisfactionquestionnaire_answer_ver_5_edited engine = myisam
SELECT serialnumber, userid, version, completetime, spendminute, entrance, 
       forum_notused, forum_improve, forum_platform, 
       livescore_notused, livescore_improve, livescore_platform, 
       buyPrediction_notUsed, buyPrediction_improve,
       ourweb, hearaboutus, suggestion, whereDoYouLive
FROM plsport_playsport.satisfactionquestionnaire_answer_ver_5;

drop table if exists plsport_playsport._q_all_answer;
create table plsport_playsport._q_all_answer engine = myisam
SELECT serialnumber, userid, version, completetime, spendminute, entrance,
       forum_notused, 
           (case when (forum_improve like '%0%') then 1 else 0 end) as f0,  /*沒有意見*/
           (case when (forum_improve like '%1%') then 1 else 0 end) as f1,  /*小白亂版*/
           (case when (forum_improve like '%3%') then 1 else 0 end) as f2,  /*工友管版不公*/
           (case when (forum_improve like '%7%') then 1 else 0 end) as f3,  /*殺手廣告文太多*/
           (case when (forum_improve like '%8%') then 1 else 0 end) as f4,  /*分析文沒用*/
           (case when (forum_improve like '%9%') then 1 else 0 end) as f5,  /*廢文太多*/
           (case when (forum_improve like '%10%') then 1 else 0 end) as f6, /*分身太多*/
       livescore_notused, 
           (case when (livescore_improve like '%0%') then 1 else 0 end) as l0, /*沒有意見*/
           (case when (livescore_improve like '%1%') then 1 else 0 end) as l1, /*比分更新太慢*/
           (case when (livescore_improve like '%5%') then 1 else 0 end) as l2, /*沒有比賽實況*/
           (case when (livescore_improve like '%6%') then 1 else 0 end) as l3, /*沒有球員數據*/
           (case when (livescore_improve like '%7%') then 1 else 0 end) as l4, /*比分常出錯*/
       buyPrediction_notUsed, 
           (case when (buyPrediction_improve like '%0%') then 1 else 0 end) as p0, /*沒有意見*/
           (case when (buyPrediction_improve like '%2%') then 1 else 0 end) as p1, /*不知道該怎麼選高手*/
           (case when (buyPrediction_improve like '%5%') then 1 else 0 end) as p2, /*沒有串關推廌*/
           (case when (buyPrediction_improve like '%6%') then 1 else 0 end) as p3, /*殺手戰績不易查詢*/
       (case when (ourweb is null) then 'no' end) as 'no_ans',
           (case when (ourweb like '%1-1%') then 1 else 0 end) as '1_1',
           (case when (ourweb like '%1-2%') then 1 else 0 end) as '1_2',
           (case when (ourweb like '%3-1%') then 1 else 0 end) as '3_1',
           (case when (ourweb like '%3-2%') then 1 else 0 end) as '3_2',
           (case when (ourweb like '%5-1%') then 1 else 0 end) as '5_1',
           (case when (ourweb like '%5-2%') then 1 else 0 end) as '5_2',
           (case when (ourweb like '%6-1%') then 1 else 0 end) as '6_1',
           (case when (ourweb like '%6-2%') then 1 else 0 end) as '6_2',
       hearAboutUS, whereDoYouLive 
FROM plsport_playsport.satisfactionquestionnaire_answer_ver_5_edited
where userid not in ('yenhsun1982', 'monkey', 'chinginge', 'pauleanr', 'ydasam', 'n12232001', 'sakyla', 'wenchi') # 工友都要排除掉
and spendminute > 0.4; # 小於30秒完成問卷的人就不計


/*--------------------------------------------
    PART.3 [圖表程式化]輸出給R使用
---------------------------------------------*/
# 輸出.csv檔給R使用
select 'serialnumber','forum_notused','f0','f1','f2','f3','f4','f5','f6',
       'livescore_notused','l0','l1','l2','l3','l4',
       'buyPrediction_notUsed','p0','p1','p2','p3','no_ans','1_1','1_2','3_1','3_2','5_1','5_2','6_1','6_2','hearAboutUS','whereDoYouLive' union (
select  serialnumber,forum_notused,f0,f1,f2,f3,f4,f5,f6,
        livescore_notused,l0,l1,l2,l3,l4,
        buyPrediction_notUsed,p0,p1,p2,p3,no_ans,1_1,1_2,3_1,3_2,5_1,5_2,6_1,6_2,hearAboutUS,whereDoYouLive
into outfile 'C:/proc/r/web_analysis/questionnaire_ver_5.csv' 
fields terminated by ',' enclosed by '"' lines terminated by '\r\n' 
FROM plsport_playsport._q_all_answer);


/*--------------------------------------------
查詢每個月問券的id
---------------------------------------------*/
select b.sn, b.ver, min(b.m) as m, b.c
from (select a.sn, a.ver, a.m, count(sn) as c from (SELECT serialnumber as sn, version as ver, substr(completetime,1,7) as m 
FROM plsport_playsport.satisfactionquestionnaire_answer) as a group by a.sn, a.ver, a.m) as b 
where b.c > 160 group by b.sn, b.ver;










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
drop table if exists questionnaire.satisfactionquestionnaire;
drop table if exists questionnaire.satisfactionquestionnaire_answer;
drop table if exists questionnaire.satisfactionquestionnaire_memberlist;
create table questionnaire.satisfactionquestionnaire engine = myisam            
select * from plsport_playsport.satisfactionquestionnaire; #主要問卷版本
create table questionnaire.satisfactionquestionnaire_answer engine = myisam     
select * from plsport_playsport.satisfactionquestionnaire_answer; #問卷的答案
create table questionnaire.satisfactionquestionnaire_memberlist engine = myisam 
select * from plsport_playsport.satisfactionquestionnaire_memberlist; #名單

use questionnaire;
/*--------------------------------------------
  (1)產生已經作過問卷的人的名單
---------------------------------------------*/
# drop table if exists questionnaire._existed_list;
# create table questionnaire._existed_list engine = myisam
# select a.userid, count(a.id) as c
# from (
#     SELECT id, serialnumber, userid, version, completetime 
#     FROM plsport_playsport.satisfactionquestionnaire_answer
#     where version = 5.0 #只限做過版本4.0的人
#     order by completetime) as a
# group by a.userid;

/*--------------------------------------------
  (1.5)產生近6個月有寫過問券的人的名單
---------------------------------------------*/
drop table if exists questionnaire._fill_question_in_6_month;
create table questionnaire._fill_question_in_6_month engine = myisam
SELECT userid 
FROM questionnaire.satisfactionquestionnaire_answer
where completeTime between subdate(now(),186) and now()
group by userid;

/*--------------------------------------------
  (2)上個月有登入過的人-主名單
---------------------------------------------*/
drop table if exists questionnaire._signin_list;
create table questionnaire._signin_list engine = myisam
select a.userid, count(a.userid) as user_count
from (
    SELECT userid, signin_time
    FROM plsport_playsport.member_signin_log_archive
    where substr(signin_time,1,7) = '2017-06') as a /*要指定上個月*/
group by a.userid;


use questionnaire;
ALTER TABLE questionnaire._signin_list ADD INDEX (`userid`); 
ALTER TABLE questionnaire._fill_question_in_6_month ADD INDEX (`userid`);

/*--------------------------------------------
  排除1: 上月份的名單, 但排除掉之前有做過問卷的人
---------------------------------------------*/
ALTER TABLE questionnaire._fill_question_in_6_month CHANGE `userid` `userid` VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE questionnaire._signin_list CHANGE `userid` `userid` VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

drop table if exists questionnaire._list;
create table questionnaire._list engine = myisam /*上月份的名單, 但排除掉近4個月做過問卷的人*/
SELECT a.userid 
FROM questionnaire._signin_list a left join questionnaire._fill_question_in_6_month b on a.userid = b.userid
where b.userid is null;/*排除掉*/

/*--------------------------------------------
  排除2:
  要先把"註冊機器人"名單生出來,
  使用8_user_find_the robot_register
---------------------------------------------*/
use questionnaire;
create table questionnaire._problem_members engine = myisam select * from plsport_playsport._problem_members;
ALTER TABLE  questionnaire._list ADD INDEX (`userid`);
ALTER TABLE  questionnaire._list CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE  questionnaire._problem_members ADD INDEX (`userid`);
ALTER TABLE  questionnaire._problem_members CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

create table questionnaire._list2 engine = myisam /*排除掉機器人*/
SELECT a.userid
FROM questionnaire._list a left join plsport_playsport._problem_members b on a.userid = b.userid
where b.userid is null; /*排除掉*/

/*--------------------------------------------
    完成名單最後階段
---------------------------------------------*/
/*最後只是要mapping上member裡的userid名稱, 問卷名單才匯的進去*/
use questionnaire;
ALTER TABLE questionnaire._list2 ADD INDEX (`userid`);
ALTER TABLE questionnaire._list2 CHANGE  `userid`  `userid` VARCHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

drop table if exists questionnaire._list_full;
create table questionnaire._list_full engine = myisam 
SELECT b.userid # 完成的名單, 使用member資料表的userid, 要不然問卷系統不能判斷大小寫的差異, 此為問券的bug
FROM questionnaire._list2 a left join plsport_playsport.member b on a.userid = b.userid;

# 先排除掉工友(有在定期做滿意度問券的工友們)
delete from questionnaire._list_full where userid = 'ydasam';
delete from questionnaire._list_full where userid = 'monkey';
delete from questionnaire._list_full where userid = 'chinginge';
delete from questionnaire._list_full where userid = 'pauleanr';
delete from questionnaire._list_full where userid = 'yenhsun1982';
delete from questionnaire._list_full where userid = 'n12232001';
delete from questionnaire._list_full where userid = 'sakyla';
delete from questionnaire._list_full where userid = 'wenchi';

drop table if exists questionnaire._list_limit_3000;
create table questionnaire._list_limit_3000 engine = myisam
SELECT * FROM questionnaire._list_full
where userid <> '' # 不知道為什麼會有一些\N出現, 所以排掉
order by rand()    # 隨機抽出3000名受測者
limit 0, 3500;     # update: 2016-07-04改為3500人

# 再把工友放進去
insert into questionnaire._list_limit_3000 values ('chinginge'),('pauleanr'),('yenhsun1982'),('sakyla'),('wenchi'),('harry1008'),('hw0710');

    #重要, 第一次執行要注意工友是否有2筆????
    # 輸出到桌面
    SELECT userid
    into outfile 'C:/Users/eddy/Desktop/questionnaire_list.csv'
    fields terminated by ',' enclosed by '' lines terminated by '\r\n' 
    FROM questionnaire._list_limit_3000; 
    
# # 檢查產生的名單中, 有沒有之前填寫過滿意度的名單
# ALTER TABLE  `_list_limit_3000` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
# ALTER TABLE  `_existed_list` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
# select a.userid from _list_limit_3000 a inner join _existed_list b on a.userid = b.userid;
# # select的結果應該是空的

ALTER TABLE  `_list_limit_3000` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  `_fill_question_in_6_month` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
select a.userid from _list_limit_3000 a inner join _fill_question_in_6_month b on a.userid = b.userid;
# select的結果應該是空的






















ALTER TABLE plsport_playsport.satisfactionquestionnaire_answer convert to character set utf8 collate utf8_general_ci;

create table plsport_playsport._questionnaire_answer_suggestion engine = myisam
SELECT a.userid, b.nickname, date(a.completetime) as date, a.suggestion 
FROM plsport_playsport.satisfactionquestionnaire_answer a left join plsport_playsport.member b on a.userid = b.userid
where a.version = 4.0 and a.suggestion <> '' and a.userid <> 'yenhsun1982'
order by completetime desc;

update plsport_playsport._questionnaire_answer_suggestion set suggestion = TRIM(suggestion);
update plsport_playsport._questionnaire_answer_suggestion set suggestion = replace(suggestion, '.',''); 
update plsport_playsport._questionnaire_answer_suggestion set suggestion = replace(suggestion, ';','');
update plsport_playsport._questionnaire_answer_suggestion set suggestion = replace(suggestion, '/','');
update plsport_playsport._questionnaire_answer_suggestion set suggestion = replace(suggestion, '\\','_');
update plsport_playsport._questionnaire_answer_suggestion set suggestion = replace(suggestion, '"','');
update plsport_playsport._questionnaire_answer_suggestion set suggestion = replace(suggestion, '&','');
update plsport_playsport._questionnaire_answer_suggestion set suggestion = replace(suggestion, '#','');
update plsport_playsport._questionnaire_answer_suggestion set suggestion = replace(suggestion, ' ','');
update plsport_playsport._questionnaire_answer_suggestion set suggestion = replace(suggestion, '\n','');
update plsport_playsport._questionnaire_answer_suggestion set suggestion = replace(suggestion, '\r','');
update plsport_playsport._questionnaire_answer_suggestion set suggestion = replace(suggestion, '\b','');
update plsport_playsport._questionnaire_answer_suggestion set suggestion = replace(suggestion, '\t','');

SELECT 'userid', 'nickname', 'date', 'suggestion' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/_questionnaire_answer_suggestion.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._questionnaire_answer_suggestion);




