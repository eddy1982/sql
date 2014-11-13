# =================================================================================================
# 任務: [201406-B-7]強化玩家搜尋-ABtesting [進行中]
# 
# 說明
#  
# 目的：了解新版玩家搜尋是否吸引使用者
# 目標：1.提升整體業績 2.玩家搜尋使用率增加
#  
# 內容
# - 測試時間：8/22~9/11 (最後一次的區間改為:9/26 14:00~10/15, 已改善誤擊的情況)
# - 設定測試組別
# - 觀察指標：1.購買預測轉換率 2.玩家搜尋整體使用率 3.搜尋bar的使用率
# - 報告時間：9/18
# =================================================================================================

create table plsport_playsport._who_buy_predict_via_user_search engine = myisam
SELECT * 
FROM plsport_playsport._predict_buyer_with_cons
where substr(position,1,2) = 'US'
and date(buy_date) between '2014-09-27' and '2014-10-15';

create table plsport_playsport._who_buy_predict_via_user_search_1 engine = myisam
select c.g, (case when (c.g < 8) then 'a' else 'b' end) as abtest, c.userid, c.buy_date, c.buy_price, c.position
from (
    SELECT (b.id%20)+1 as g, a.buyerid as userid, a.buy_date, a.buy_price, a.position
    FROM plsport_playsport._who_buy_predict_via_user_search a left join plsport_playsport.member b on a.buyerid = b.userid) as c;

create table plsport_playsport._who_buy_predict_via_user_search_2 engine = myisam
select a.g, a.abtest, a.userid, a.buy_date, a.buy_price, a.position, a.p
from (
    SELECT g, abtest, userid, buy_date, buy_price, position, concat(abtest,'_',position) as p
    FROM plsport_playsport._who_buy_predict_via_user_search_1) as a;

#  查詢1 - 依次數
SELECT abtest, position, count(userid) as c 
FROM plsport_playsport._who_buy_predict_via_user_search_2
group by abtest, position;

#  查詢2 - 依收益
SELECT abtest, position, sum(buy_price) as revenue 
FROM plsport_playsport._who_buy_predict_via_user_search_2
group by abtest, position;

# <<< 2014-10-01 修正 - 檢查是那些人誤買到不同版本的
SELECT p, count(userid) as c 
FROM plsport_playsport._who_buy_predict_via_user_search_2
group by p;

        # <<< 2014-10-15 修正 - 檢查是那些人誤買到不同版本的
        SELECT * FROM plsport_playsport._who_buy_predict_via_user_search_2
        where userid in (SELECT userid 
                        FROM plsport_playsport._who_buy_predict_via_user_search_2
                        where abtest = 'a'
                        and position in ('US_S','US_H')
                        group by userid)
        order by userid;
        # <<< 2014-10-15 修正 - 檢查是那些人誤買到不同版本的
        SELECT userid 
        FROM plsport_playsport._who_buy_predict_via_user_search_2
        where abtest = 'a'
        and position in ('US_S','US_H')
        group by userid;

create table plsport_playsport._who_need_to_be_excluded engine = myisam
SELECT userid
FROM plsport_playsport._who_buy_predict_via_user_search_2
where p in ('a_US_H', 'a_US_S')
group by userid;

create table plsport_playsport._who_buy_predict_via_user_search_3 engine = myisam
SELECT a.g, a.abtest, a.userid, a.buy_date, a.buy_price, a.position, a.p 
FROM plsport_playsport._who_buy_predict_via_user_search_2 a left join plsport_playsport._who_need_to_be_excluded b on a.userid = b.userid
where b.userid is null;

create table plsport_playsport._list_1 engine = myisam
SELECT abtest, userid, sum(buy_price) as spent_us
FROM plsport_playsport._who_buy_predict_via_user_search_3
group by abtest, userid;

create table plsport_playsport._spent_total engine = myisam
select a.userid, sum(a.buy_price) as spent_total
from (
    SELECT buyerid as userid, buy_date, buy_price 
    FROM plsport_playsport._predict_buyer_with_cons
    where date(buy_date) between '2014-08-22' and '2014-09-30') as a
group by a.userid;

        # (1)完整的收益名單(玩家搜尋頁面abtesting)
        create table plsport_playsport._list_2 engine = myisam
        SELECT a.abtest, a.userid, a.spent_us, b.spent_total
        FROM plsport_playsport._list_1 a left join plsport_playsport._spent_total b on a.userid = b.userid;

        # (2)在玩家搜尋頁面的log (單純在玩家搜尋)
        create table actionlog.action_search engine = myisam
        SELECT userid, uri, time, platform_type 
        FROM actionlog.action_201409
        where uri like '%usersearch.php%'
        and date(time) between '2014-09-27' and '2014-09-30';

        insert into actionlog.action_search 
        select userid, uri, time, platform_type 
        FROM actionlog.action_20141015
        where uri like '%usersearch.php%'
        and date(time) between '2014-10-01' and '2014-10-15';

        # (3)在玩家搜尋頁面點擊後的的log (前往個人頁, 這裡才有誤擊記錄)
        create table actionlog.action_search_to_member engine = myisam
        SELECT userid, uri, time, platform_type 
        FROM actionlog.action_201409
        where uri like '%rp=US%'
        and date(time) between '2014-09-27' and '2014-09-30';

        insert into actionlog.action_search_to_member
        select userid, uri, time, platform_type 
        FROM actionlog.action_20141015
        where uri like '%rp=US%'
        and date(time) between '2014-10-01' and '2014-10-15';

                ALTER TABLE actionlog.action_search  CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
                ALTER TABLE actionlog.action_search_to_member CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

# 要先從(3)找出有誰曾誤點過
# 不用找了, 直接用_who_need_to_be_excluded的名單即可


create table actionlog.action_search_1 engine = myisam
SELECT userid, uri, time, platform_type, (case when (locate('searchuser=',uri) >0) then '1' else '0' end) as status
FROM actionlog.action_search
where userid <> '';

create table actionlog.action_search_2 engine = myisam
select c.g, (case when (c.g < 8) then 'a' else 'b' end) as abtest, c.userid, c.uri, c.time, c.platform_type, c.status
from (
    SELECT (b.id%20)+1 as g, a.userid, a.uri, a.time, a.platform_type, a.status 
    FROM actionlog.action_search_1 a left join plsport_playsport.member b on a.userid = b.userid) as c;

create table actionlog.action_search_3 engine = myisam # 排除掉誤擊的名單
SELECT a.abtest, a.userid, a.uri, a.time, a.status
FROM actionlog.action_search_2 a left join plsport_playsport._who_need_to_be_excluded b on a.userid = b.userid
where b.userid is null;

# 計算有沒有點擊搜尋bar的功能 卡方檢驗
select a.abtest, a.status, count(userid) as c
from (
    SELECT abtest, userid, status, count(userid) as c
    FROM actionlog.action_search_3
    group by abtest, userid, status) as a
group by a.abtest, a.status;

# A: 2241 > 1405 > 63%
# B: 4105 > 3302 > 80% V 
# Test "B" converted 28% better than Test "A." We are 100% certain that the changes in Test "B" will improve your conversion rate.

create table actionlog.action_search_to_member_1 engine = myisam
SELECT userid, uri, time, platform_type, substr(uri,locate('ucp=',uri)+4,length(uri)) as location
FROM actionlog.action_search_to_member;

create table actionlog.action_search_to_member_2 engine = myisam
select a.userid, a.uri, a.time, a.platform_type, substr(a.f,1,locate('&',a.f)-1) as f,a.location as p
from (
    SELECT userid, uri, time, platform_type, location, substr(uri,locate('rp=',uri)+3,length(uri)) as f
    FROM actionlog.action_search_to_member_1) as a
where a.userid <> '';


        # 2014-10-15 檢查-------------------------------------------------------------------------------------------------------------------------
        create table actionlog.action_search_to_member_for_test engine = myisam
        select a.userid, a.uri, a.time, a.platform_type, (case when (locate('&',a.p)=0) then a.p else substr(a.p,1,locate('&',a.p)-1) end) as p
        from (
            SELECT userid, uri, time, platform_type, substr(uri, locate('&rp=',uri)+4, length(uri)) as p
            FROM actionlog.action_search_to_member
            where userid <> '') as a;

        ALTER TABLE actionlog.action_search_to_member_for_test CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

        create table actionlog.action_search_to_member_for_test_1 engine = myisam
        SELECT (b.id%20)+1 as g, a.userid, a.uri, a.time, a.platform_type, a.p 
        FROM actionlog.action_search_to_member_for_test a left join plsport_playsport.member b on a.userid = b.userid;
        
        # 提供給壯兔或晨暐檢查的完整誤擊記錄表格
        # http://pm.playsport.cc/index.php/tasksComments?tasksId=3419&projectId=11
        create table actionlog.action_search_to_member_for_test_2 engine = myisam
        SELECT g, (case when (g<8) then 'a' else 'b' end) as abtest, userid, uri, time , platform_type, p 
        FROM actionlog.action_search_to_member_for_test_1;
        # ----------------------------------------------------------------------------------------------------------------------------------------


create table actionlog.action_search_to_member_3 engine = myisam
SELECT a.userid, a.uri, a.time, a.f, a.p 
FROM actionlog.action_search_to_member_2 a left join plsport_playsport._who_need_to_be_excluded b on a.userid = b.userid
where b.userid is null;

# 計算點擊的位置
SELECT f, p, count(userid) as c 
FROM actionlog.action_search_to_member_3
group by f, p
order by f, p;

# 阿達補充要求比較個人頁有無顯著 2014-09-22

        # 在玩家搜尋頁面點擊後的的log
        create table actionlog.action_search_to_member_rp engine = myisam
        SELECT userid, uri, time, platform_type 
        FROM actionlog.action_201408
        where uri like '%rp=%'
        and date(time) between '2014-08-22' and '2014-08-31';

        insert into actionlog.action_search_to_member_rp
        select userid, uri, time, platform_type 
        FROM actionlog.action_201409_30
        where uri like '%rp=%'
        and date(time) between '2014-09-01' and '2014-09-30';

create table actionlog.action_search_to_member_rp_1 engine = myisam
select a.userid, a.uri, a.time, a.p
from (
    SELECT userid, uri, time, substr(uri, locate('&rp=',uri)+4, length(uri)) as p
    FROM actionlog.action_search_to_member_rp
    where userid <> '') as a
where substr(a.p,1,2) = "US";

create table actionlog.action_search_to_member_rp_2 engine = myisam
SELECT userid, uri, time, substr(p,1,5) as p
FROM actionlog.action_search_to_member_rp_1;

# 檢查
SELECT p, count(userid) as c 
FROM actionlog.action_search_to_member_rp_2
group by p;

# US_H  59203
# US_HB 7594
# US_RS 53351
# US_RV 25019
# US_S  136162
# US_SB 11656

ALTER TABLE actionlog.action_search_to_member_rp_2 CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

create table actionlog.action_search_to_member_rp_3 engine = myisam
select (case when (c.g < 8) then 'a' else 'b' end) as g, c.userid, c.uri, c.time, c.p, c.pp
from (
    SELECT (b.id%20)+1 as g, a.userid, a.uri, a.time, a.p, length(a.p) as pp
    FROM actionlog.action_search_to_member_rp_2 a left join plsport_playsport.member b on a.userid = b.userid) as c;

create table actionlog.action_search_to_member_rp_4 engine = myisam
select a.g, a.userid, a.uri, a.time, a.p, a.con
from (
    SELECT g, userid, uri, time, p, concat(g,pp) as con 
    FROM actionlog.action_search_to_member_rp_3
    order by pp desc) as a;

SELECT g, con, count(userid) as c 
FROM actionlog.action_search_to_member_rp_4
group by g, con;

create table actionlog._who_click_wrong_version engine = myisam
SELECT userid
FROM actionlog.action_search_to_member_rp_4
where con in ('a4','b5')
group by userid;

create table actionlog.action_search_to_member_rp_5 engine = myisam
SELECT g, userid, count(userid) as visit_member_pv 
FROM actionlog.action_search_to_member_rp_4
group by g, userid;

create table actionlog.action_search_to_member_rp_6 engine = myisam
SELECT a.g, a.userid, a.visit_member_pv  
FROM actionlog.action_search_to_member_rp_5 a left join actionlog._who_click_wrong_version b on a.userid = b.userid
where b.userid is null;


# 靜怡要補充的a/b testing
create table actionlog.action_search_2_only_search_php engine = myisam
select *
from (
    SELECT g, abtest, userid, uri, time, platform_type, status, length(uri) as c
    FROM actionlog.action_search_2) as a
where a.c = 15;

create table actionlog.action_search_2_only_search_php_1 engine = myisam
SELECT abtest, userid, count(userid) as c 
FROM actionlog.action_search_2_only_search_php
group by abtest, userid;

create table actionlog.action_search_2_only_search_php_2 engine = myisam
SELECT a.abtest, a.userid, a.c
FROM actionlog.action_search_2_only_search_php_1 a left join actionlog._who_click_wrong_version b on a.userid = b.userid
where b.userid is null;


# 阿達第二次補充要求比較完整usersearch.php(包含參數) 2014-10-02
create table actionlog.action_search_4 engine = myisam
SELECT a.abtest, a.userid, a.uri 
FROM actionlog.action_search_2 a left join actionlog._who_click_wrong_version b on a.userid = b.userid
where b.userid is null;

create table actionlog.action_search_5 engine = myisam
SELECT abtest, userid, count(userid) as c 
FROM actionlog.action_search_4
group by abtest, userid;


create table actionlog.action_search_5_1 engine = myisam
SELECT abtest, userid, count(userid) as c 
FROM actionlog.action_search_2
group by abtest, userid;


# 1.阿達要看的個人頁abtesting
#   action_search_to_member_rp_6
# 2.阿達要看的所有搜尋頁
#   action_search_5
# 3.靜怡進入玩家搜尋的頁數次數
#   action_search_2_only_search_php_2

select 'abtest', 'usreid', 'c' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/ydasam_visitmember_page.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog.action_search_to_member_rp_6);

select 'abtest', 'usreid', 'c' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/ydasam_all_search_page.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog.action_search_5);

select 'abtest', 'usreid', 'c' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/ydasam_all_search_page1.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog.action_search_5_1);

select 'abtest', 'usreid', 'c' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/ching_enter_usersearch.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog.action_search_2_only_search_php_2);

# 不知道這是幹什麼用的
create table actionlog.action_search_2_all_search_php engine = myisam
SELECT abtest, userid, count(uri) as c 
FROM actionlog.action_search_2
group by abtest, userid;

# 要給晨暐檢察的內容 - 異常log, 某些使用者會造訪新/舊2個版本的頁面
create table actionlog.action_search_to_member_rp_3_for_check engine = myisam
SELECT * FROM actionlog.action_search_to_member_rp
where userid = 'jacky558899'
and uri like '%rp=US%'
order by time desc;

select a.g,  a.p, count(userid) as c
from (
    SELECT g, userid, uri, time, p, concat(g,pp) as con 
    FROM actionlog.action_search_to_member_rp_3
    order by pp desc) as a
group by a.g, a.p;

        # 2014-09-25補充 (要給晨暐檢察的內容)
        create table actionlog.action_search_to_member_rp_3_who_mistake_hit engine = myisam
        select userid, count(userid) as pv
        from (
            select *
            from (
                SELECT g, userid, uri, time, p, pp, concat(g,pp) as chk 
                FROM actionlog.action_search_to_member_rp_3) as a
            where a.chk = 'a4') as b # a4是錯的, a5是對的, 所以捉a4就好
        group by userid;

        create table actionlog.action_search_to_member_rp_3_who_mistake_hit_all engine = myisam
        select userid, count(userid) as pv
        from (
            select *
            from (
                SELECT g, userid, uri, time, p, pp, concat(g,pp) as chk 
                FROM actionlog.action_search_to_member_rp_3) as a
            where a.chk in ('a4','a5')) as b 
        group by userid;

        create table actionlog.action_search_to_member_rp_3_who_mistake_hit_all_full_list engine = myisam
        SELECT a.userid, a.pv, b.pv as mistake_pv 
        FROM actionlog.action_search_to_member_rp_3_who_mistake_hit_all a left join actionlog.action_search_to_member_rp_3_who_mistake_hit b on a.userid = b.userid
        where b.pv is not null;

        create table actionlog.action_search_to_member_rp_3_who_mistake_hit_all_full_list_ok engine = myisam
        SELECT (b.id%20)+1 as g, a.userid, a.pv, a.mistake_pv
        FROM actionlog.action_search_to_member_rp_3_who_mistake_hit_all_full_list a left join plsport_playsport.member b on a.userid = b.userid;



# ----------------------------------------------------------------------------------------------------------------------
# 第二次檢查 2014-11-13
# 結果發現是使用者都把搜尋結果都加入我的最愛, 導致會點選到錯誤的追蹤碼, 約有1/10左右的記錄有這樣的結果
# ----------------------------------------------------------------------------------------------------------------------

create table actionlog.action_log_usersearch engine = myisam
SELECT userid, uri, time 
FROM actionlog.action_20141104
where time between '2014-11-03 16:00:00' and '2014-11-04 16:00:00'
and userid <> ''
and uri like '%usersearch%' ;

ALTER TABLE `action_log_usersearch` CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

create table plsport_playsport._check_list engine = myisam
SELECT (b.id%20)+1 as g, a.userid, a.uri, a.time 
FROM actionlog.action_log_usersearch a left join plsport_playsport.member b on a.userid = b.userid;

create table plsport_playsport._check_list1 engine = myisam
SELECT (case when (g<8) then 'a' else 'b' end) as abtest, g, userid, uri, substr(uri,1,15) as u, time 
FROM plsport_playsport._check_list;


# 檢查只有玩家搜尋的點擊
create table actionlog.action_log_position_us engine = myisam
SELECT userid, uri, time 
FROM actionlog.action_20141104
where time between '2014-11-03 16:00:00' and '2014-11-04 16:00:00'
and userid <> ''
and uri like '%rp=US%' ;

create table plsport_playsport._check_list_us engine = myisam
select a.userid, a.uri, a.time, (case when (locate('&',a.p)=0) then a.p else substr(a.p,1,locate('&',a.p)-1) end) as p
from (
    SELECT userid, uri, time, substr(uri, locate('rp=',uri)+3, length(uri)) as p
    FROM actionlog.action_log_position_us) as a;

ALTER TABLE plsport_playsport._check_list_us CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

create table plsport_playsport._check_list_us_1 engine = myisam
SELECT (b.id%20)+1 as g, a.userid, a.uri, a.time, a.p
FROM plsport_playsport._check_list_us a left join plsport_playsport.member b on a.userid = b.userid;

create table plsport_playsport._check_list_us_2 engine = myisam
SELECT (case when (g<8) then 'a' else 'b' end) as abtest, g, userid, uri, time, p 
FROM plsport_playsport._check_list_us_1;

SELECT abtest, p, count(userid) as c 
FROM plsport_playsport._check_list_us_2
group by abtest, p;

SELECT * FROM plsport_playsport._check_list_us_2
where userid in (
                SELECT userid 
                FROM plsport_playsport._check_list_us_2
                where p in ('US_H','US_S')
                and abtest = 'a'
                group by userid);

create table actionlog.action_log_find_problem_user engine = myisam
SELECT *
FROM actionlog.action_20141104
where time between '2014-11-03 16:00:00' and '2014-11-04 16:00:00'
and userid <> '';

ALTER TABLE actionlog.action_log_find_problem_user CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

create table actionlog.action_log_find_problem_user_1 engine = myisam
SELECT * FROM actionlog.action_log_find_problem_user
where userid in (
                SELECT userid 
                FROM plsport_playsport._check_list_us_2
                where p in ('US_H','US_S')
                and abtest = 'a'
                group by userid)
order by userid, time;

SELECT * FROM actionlog.action_log_find_problem_user_1;

create table actionlog.action_log_find_problem_user_2 engine = myisam
SELECT (b.id%20)+1 as g, a.userid, a.uri, a.time, a.user_agent, platform_type
FROM actionlog.action_log_find_problem_user_1 a left join plsport_playsport.member b on a.userid = b.userid;

SELECT * FROM actionlog.action_log_find_problem_user_2;

SELECT 'g', 'userid', 'uri', 'time', 'user_agent', 'platform_type' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/action_log_find_problem_user_2.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog.action_log_find_problem_user_2);

# 檢查只有玩家搜尋的點擊 (在visit_member.php中)
use actionlog;
create table actionlog.action_log_position_use engine = myisam
SELECT userid, uri, time 
FROM actionlog.action_201411
where userid <> ''
and uri like '%rp=US%';

create table actionlog.action_log_position_use_1 engine = myisam
SELECT * FROM actionlog.action_log_position_use
where time between '2014-11-06 00:00:00' and '2014-11-09 23:59:59'
order by time desc;

create table actionlog.action_log_position_use_2 engine = myisam
select a.userid, a.uri, a.time, (case when (locate('&',a.p)=0) then a.p else substr(a.p,1,locate('&',a.p)-1) end) as p
from (
    SELECT userid, uri, time, substr(uri,locate('rp=',uri)+3,length(uri)) as p 
    FROM actionlog.action_log_position_use_1) as a;

ALTER TABLE actionlog.action_log_position_use_2 CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

create table actionlog.action_log_position_use_3 engine = myisam
SELECT (b.id%20)+1 as g, a.userid, a.uri, a.time, a.p
FROM actionlog.action_log_position_use_2 a left join plsport_playsport.member b on a.userid = b.userid;

create table actionlog.action_log_position_use_4 engine = myisam
SELECT (case when (g<8) then 'a' else 'b' end) as abtest, g, userid, uri, time, p
FROM actionlog.action_log_position_use_3;

create table actionlog.action_log_position_use_5 engine = myisam
select a.abtest, a.g, a.userid, a.uri, a.time, a.p, substr(a.visit,1,locate('&',a.visit)-1) as visit
from (
    SELECT abtest, g, userid, uri, time, p, substr(uri,locate('visit=',uri)+6,length(uri)) as visit
    FROM actionlog.action_log_position_use_4) as a;

use actionlog;
ALTER TABLE `action_log_position_use_5` CHANGE `visit` `visit` LONGTEXT CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE `action_log_position_use_5` CHANGE `visit` `visit` VARCHAR(35) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
ALTER TABLE `action_log_position_use_5` ADD INDEX(`visit`);

create table actionlog.action_log_position_use_6 engine = myisam
SELECT a.abtest, a.g, a.userid, a.uri, a.time, a.p, a.visit, b.nickname  
FROM actionlog.action_log_position_use_5 a left join plsport_playsport.member b on a.visit = b.userid;

# 輸出txt
SELECT 'abtest', 'g', 'userid', 'uri', 'time', 'p', 'visit', 'nickname' union (
SELECT *
into outfile 'C:/Users/1-7_ASUS/Desktop/action_log_position_use_6.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM actionlog.action_log_position_use_6);
