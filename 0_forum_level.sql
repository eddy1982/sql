


create table plsport_playsport._forum_in3years engine = myisam
SELECT subjectid, subject, postuser, posttime, year(posttime) as y, allianceid, viewtimes, replycount, pushcount
FROM plsport_playsport.forum
where year(posttime) in (2012,2013,2014)
and allianceid not in (112,111,99,95);

# 輸出.txt
select 'subjectid','posttime','y','allianceid','viewtimes','replycount','pushcount' union(
SELECT subjectid, posttime, y, allianceid, viewtimes, replycount, pushcount
into outfile 'C:/Users/1-7_ASUS/Desktop/_forum_in3years.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._forum_in3years);


create table plsport_playsport._forum_in3years_1 engine = myisam
SELECT a.subjectid, a.subject, a.postuser, b.nickname, a.posttime, a.y, a.allianceid, a.viewtimes, a.replycount, a.pushcount 
FROM plsport_playsport._forum_in3years a left join plsport_playsport.member b on a.postuser = b.userid;

UPDATE plsport_playsport._forum_in3years_1 set nickname  = TRIM(nickname);            #刪掉空白字完
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, '.',''); #清除nickname奇怪的符號...
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, ',','');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, 'php','');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, 'admin','');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, ';','');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, '%','');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, '/','');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, '\\','_');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, '+','');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, '-','');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, '*','');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, '#','');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, '&','');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, '$','');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, '^','');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, '~','');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, '!','');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, '?','');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, '"','');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, ' ','_');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, '@','at');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, ':','');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, '','_');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, '∼','_');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, 'циндаогрыжа','_');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, '','_');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, '�','_');
update plsport_playsport._forum_in3years_1 set nickname  = replace(nickname, '▽','_');

create table plsport_playsport._forum_in3years_2 engine = myisam
SELECT subjectid, subject, postuser, substr(nickname,1,12) as nickname, posttime, y, allianceid, viewtimes, replycount, pushcount 
FROM plsport_playsport._forum_in3years_1;


# 處理回文
create table plsport_playsport._forumcontent engine = myisam
SELECT articleid, subjectid, userid, postdate 
FROM plsport_playsport.forumcontent;

create table plsport_playsport._forumcontent_archive engine = myisam
SELECT articleid, subjectid, userid, postdate 
FROM plsport_playsport.forumcontent_archive;

insert ignore into plsport_playsport._forumcontent select * from plsport_playsport._forumcontent_archive;

    ALTER TABLE plsport_playsport._forumcontent ADD INDEX (`subjectid`);
    ALTER TABLE plsport_playsport._forumcontent ADD INDEX (`userid`);

# 計算約400secs
create table plsport_playsport._forumcontent_grouped engine = myisam
SELECT userid, subjectid, count(subjectid) as reply_count
FROM plsport_playsport._forumcontent
group by userid, subjectid;

# (1)每位user的回覆文章的篇數(一篇多回只+1)
create table plsport_playsport._forumcontent_grouped_1 engine = myisam
SELECT userid, count(subjectid) as reply_count 
FROM plsport_playsport._forumcontent_grouped
where userid <> ''
group by userid;

# (2)每位user的發文數統計
create table plsport_playsport._post_count engine = myisam
SELECT postuser, count(subjectid) as post_count 
FROM plsport_playsport._forum_in3years_2
where postuser <> ''
group by nickname;

    ALTER TABLE plsport_playsport._forumcontent_grouped_1 ADD INDEX (`userid`);
    ALTER TABLE plsport_playsport._post_count ADD INDEX (`postuser`);

create table plsport_playsport._post_and_reply engine = myisam
select c.id, c.userid, c.nickname, c.post_count, d.reply_count
from (
	SELECT a.id, a.userid, a.nickname, b.post_count
	FROM plsport_playsport.member a left join plsport_playsport._post_count b on a.userid = b.postuser) as c
    left join plsport_playsport._forumcontent_grouped_1 as d on c.userid = d.userid;

create table plsport_playsport._post_and_reply_1 engine = myisam
select b.id, b.userid, b.nickname, b.post_count, b.reply_count
from (
	select a.id, a.userid, a.nickname, a.post_count, a.reply_count, (a.post_count+a.reply_count) as t
	from (
		SELECT id, userid, nickname, (case when (post_count is not null) then post_count else 0 end) as post_count,
									 (case when (reply_count is not null) then reply_count else 0 end) as reply_count
		FROM plsport_playsport._post_and_reply) as a) as b
where b.t > 0;


UPDATE plsport_playsport._post_and_reply_1 set nickname  = TRIM(nickname);            #刪掉空白字完
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, '.',''); #清除nickname奇怪的符號...
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, ',','');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, 'php','');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, 'admin','');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, ';','');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, '%','');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, '/','');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, '\\','_');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, '+','');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, '-','');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, '*','');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, '#','');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, '&','');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, '$','');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, '^','');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, '~','');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, '!','');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, '?','');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, '"','');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, ' ','_');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, '@','at');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, ':','');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, '','_');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, '∼','_');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, 'циндаогрыжа','_');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, '','_');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, '�','_');
update plsport_playsport._post_and_reply_1 set nickname  = replace(nickname, '▽','_');
UPDATE plsport_playsport._post_and_reply_1 set userid  = TRIM(userid);            #刪掉空白字完
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, '.',''); #清除userid奇怪的符號...
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, ',','');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, 'php','');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, 'admin','');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, ';','');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, '%','');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, '/','');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, '\\','_');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, '+','');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, '-','');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, '*','');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, '#','');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, '&','');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, '$','');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, '^','');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, '~','');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, '!','');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, '?','');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, '"','');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, ' ','_');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, '@','at');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, ':','');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, '','_');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, '∼','_');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, 'циндаогрыжа','_');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, '','_');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, '�','_');
update plsport_playsport._post_and_reply_1 set userid  = replace(userid, '▽','_');


# 輸出.txt
select 'id','userid','nickname','post_count','reply_count' union(
SELECT id, substr(userid,1,12) as userid, substr(nickname,1,12) as nickname, post_count, reply_count
into outfile 'C:/proc/r/forum_level/_post_and_reply.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport._post_and_reply_1);







# 每位user的發文數統計with 30推
create table plsport_playsport._post_with_30_push engine = myisam
select *
from (
	SELECT postuser, count(subjectid) as post_count_with_more_30_push 
	FROM plsport_playsport._forum_in3years_2
	where pushcount >= 30
	group by postuser) as a
order by a.post_count_with_more_30_push desc;

# 每位user的發文數統計with 20回覆
create table plsport_playsport._post_with_20_reply engine = myisam
select *
from (
	SELECT postuser, count(subjectid) as post_count_with_more_20_reply 
	FROM plsport_playsport._forum_in3years_2
	where replycount >= 20
	group by postuser) as a
order by a.post_count_with_more_20_reply desc;





