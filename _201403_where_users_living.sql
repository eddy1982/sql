/*************************************************************************
	捉出居住地有填寫的使用者


**************************************************************************/

use plsport_playsport;
ALTER TABLE  `user_living_city` CHANGE  `userid`  `userid` VARCHAR( 255 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;
ALTER TABLE  `member` CHANGE  `userid`  `userid` CHAR( 22 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ;

/*(1)居住地*/
create table plsport_playsport._user_living_city engine = myisam
SELECT b.id, a.userid, a.city, 
       (case when (a.city=0) then '基隆'
			 when (a.city=1) then '北市' 
			 when (a.city=2) then '新北' 
			 when (a.city=3) then '桃園' 
			 when (a.city=4) then '新竹' 
			 when (a.city=6) then '苗栗' 
			 when (a.city=7) then '台中' 
			 when (a.city=9) then '彰化' 
			 when (a.city=10) then '南投' 
			 when (a.city=11) then '嘉義' 
			 when (a.city=13) then '雲林' 
			 when (a.city=14) then '台南' 
			 when (a.city=16) then '高雄' 
			 when (a.city=18) then '屏東' 
			 when (a.city=19) then '宜蘭' 
			 when (a.city=20) then '花蓮' 
			 when (a.city=21) then '台東' 
			 when (a.city=25) then '外島' 			
             when (a.city=26) then '海外' end ) as city1
FROM plsport_playsport.user_living_city a left join plsport_playsport.member b on a.userid = b.userid
where action = 1; #action=1代表有填寫, 其它的為沒填

/*(2)當過殺手資料*/
create table plsport_playsport._medal_fire engine = myisam
SELECT b.id, a.userid, count(a.id) as dc
FROM plsport_playsport.medal_fire a left join plsport_playsport.member b on a.userid = b.userid
group by a.userid;
/*(3)買過預測*/
create table plsport_playsport._pcash_log engine = myisam
SELECT b.id, a.userid, sum(a.amount) as paid_money, count(a.id) as buy_count
FROM plsport_playsport.pcash_log a left join plsport_playsport.member b on a.userid = b.userid
where a.userid <> " "
group by a.userid;
/*(4)歷史發文資料*/
create table plsport_playsport._forum engine = myisam
SELECT b.id, a.postuser as userid, count(a.subjectid) as post_count
FROM plsport_playsport.forum a left join plsport_playsport.member b on a.postuser = b.userid
where a.postuser <> " "
group by a.postuser;