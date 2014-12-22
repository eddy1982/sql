create table actionlog_page_pv.action_forum_201401 engine = myisam
SELECT userid, uri, time, platform_type FROM actionlog.action_201401
where uri like '%/forum%';

create table actionlog_page_pv.action_forum_201402 engine = myisam
SELECT userid, uri, time, platform_type FROM actionlog.action_201402
where uri like '%/forum%';

create table actionlog_page_pv.action_forum_201403 engine = myisam
SELECT userid, uri, time, platform_type FROM actionlog.action_201403
where uri like '%/forum%';

create table actionlog_page_pv.action_forum_201404 engine = myisam
SELECT userid, uri, time, platform_type FROM actionlog.action_201404
where uri like '%/forum%';

create table actionlog_page_pv.action_forum_201405 engine = myisam
SELECT userid, uri, time, platform_type FROM actionlog.action_201405
where uri like '%/forum%';

create table actionlog_page_pv.action_forum_201406 engine = myisam
SELECT userid, uri, time, platform_type FROM actionlog.action_201406
where uri like '%/forum%';

create table actionlog_page_pv.action_forum_201407 engine = myisam
SELECT userid, uri, time, platform_type FROM actionlog.action_201407
where uri like '%/forum%';

create table actionlog_page_pv.action_forum_201408 engine = myisam
SELECT userid, uri, time, platform_type FROM actionlog.action_201408
where uri like '%/forum%';

create table actionlog_page_pv.action_forum_201409 engine = myisam
SELECT userid, uri, time, platform_type FROM actionlog.action_201409
where uri like '%/forum%';

create table actionlog_page_pv.action_forum_201410 engine = myisam
SELECT userid, uri, time, platform_type FROM actionlog.action_201410
where uri like '%/forum%';

create table actionlog_page_pv.action_forum_201411 engine = myisam
SELECT userid, uri, time, platform_type FROM actionlog.action_201411
where uri like '%/forum%';

create table actionlog_page_pv.action_livescore_201401 engine = myisam
SELECT userid, uri, time, platform_type FROM actionlog.action_201401
where uri like '%/livescore%';

create table actionlog_page_pv.action_livescore_201402 engine = myisam
SELECT userid, uri, time, platform_type FROM actionlog.action_201402
where uri like '%/livescore%';

create table actionlog_page_pv.action_livescore_201403 engine = myisam
SELECT userid, uri, time, platform_type FROM actionlog.action_201403
where uri like '%/livescore%';

create table actionlog_page_pv.action_livescore_201404 engine = myisam
SELECT userid, uri, time, platform_type FROM actionlog.action_201404
where uri like '%/livescore%';

create table actionlog_page_pv.action_livescore_201405 engine = myisam
SELECT userid, uri, time, platform_type FROM actionlog.action_201405
where uri like '%/livescore%';

create table actionlog_page_pv.action_livescore_201406 engine = myisam
SELECT userid, uri, time, platform_type FROM actionlog.action_201406
where uri like '%/livescore%';

create table actionlog_page_pv.action_livescore_201407 engine = myisam
SELECT userid, uri, time, platform_type FROM actionlog.action_201407
where uri like '%/livescore%';

create table actionlog_page_pv.action_livescore_201408 engine = myisam
SELECT userid, uri, time, platform_type FROM actionlog.action_201408
where uri like '%/livescore%';

create table actionlog_page_pv.action_livescore_201409 engine = myisam
SELECT userid, uri, time, platform_type FROM actionlog.action_201409
where uri like '%/livescore%';

create table actionlog_page_pv.action_livescore_201410 engine = myisam
SELECT userid, uri, time, platform_type FROM actionlog.action_201410
where uri like '%/livescore%';

create table actionlog_page_pv.action_livescore_201411 engine = myisam
SELECT userid, uri, time, platform_type FROM actionlog.action_201411
where uri like '%/livescore%';








create table actionlog_page_pv._forum_pv engine = myisam
select a.d, count(a.userid) as pv
from (
	SELECT userid, uri, date(time) as d, platform_type 
	FROM actionlog_page_pv.action_forum_201401
	where month(time) = 1) as a group by a.d;
insert ignore into actionlog_page_pv._forum_pv
select a.d, count(a.userid) as pv
from (
	SELECT userid, uri, date(time) as d, platform_type 
	FROM actionlog_page_pv.action_forum_201402
    where month(time) = 2) as a group by a.d;
insert ignore into actionlog_page_pv._forum_pv
select a.d, count(a.userid) as pv
from (
	SELECT userid, uri, date(time) as d, platform_type 
	FROM actionlog_page_pv.action_forum_201403
    where month(time) = 3) as a group by a.d;
insert ignore into actionlog_page_pv._forum_pv
select a.d, count(a.userid) as pv
from (
	SELECT userid, uri, date(time) as d, platform_type 
	FROM actionlog_page_pv.action_forum_201404
    where month(time) = 4) as a group by a.d;
insert ignore into actionlog_page_pv._forum_pv
select a.d, count(a.userid) as pv
from (
	SELECT userid, uri, date(time) as d, platform_type 
	FROM actionlog_page_pv.action_forum_201405
    where month(time) = 5) as a group by a.d;
insert ignore into actionlog_page_pv._forum_pv
select a.d, count(a.userid) as pv
from (
	SELECT userid, uri, date(time) as d, platform_type 
	FROM actionlog_page_pv.action_forum_201406
	where month(time) = 6) as a group by a.d;
insert ignore into actionlog_page_pv._forum_pv
select a.d, count(a.userid) as pv
from (
	SELECT userid, uri, date(time) as d, platform_type 
	FROM actionlog_page_pv.action_forum_201407
    where month(time) = 7) as a group by a.d;
insert ignore into actionlog_page_pv._forum_pv
select a.d, count(a.userid) as pv
from (
	SELECT userid, uri, date(time) as d, platform_type 
	FROM actionlog_page_pv.action_forum_201408
    where month(time) = 8) as a group by a.d;
insert ignore into actionlog_page_pv._forum_pv
select a.d, count(a.userid) as pv
from (
	SELECT userid, uri, date(time) as d, platform_type 
	FROM actionlog_page_pv.action_forum_201409
    where month(time) = 9) as a group by a.d;
insert ignore into actionlog_page_pv._forum_pv
select a.d, count(a.userid) as pv
from (
	SELECT userid, uri, date(time) as d, platform_type 
	FROM actionlog_page_pv.action_forum_201410
    where month(time) = 10) as a group by a.d;
insert ignore into actionlog_page_pv._forum_pv
select a.d, count(a.userid) as pv
from (
	SELECT userid, uri, date(time) as d, platform_type 
	FROM actionlog_page_pv.action_forum_201411
    where month(time) = 11) as a group by a.d;









create table actionlog_page_pv._livescore_pv engine = myisam
select a.d, count(a.userid) as pv
from (
	SELECT userid, uri, date(time) as d, platform_type 
	FROM actionlog_page_pv.action_livescore_201401
	where month(time) = 1) as a group by a.d;
insert ignore into actionlog_page_pv._livescore_pv
select a.d, count(a.userid) as pv
from (
	SELECT userid, uri, date(time) as d, platform_type 
	FROM actionlog_page_pv.action_livescore_201402
    where month(time) = 2) as a group by a.d;
insert ignore into actionlog_page_pv._livescore_pv
select a.d, count(a.userid) as pv
from (
	SELECT userid, uri, date(time) as d, platform_type 
	FROM actionlog_page_pv.action_livescore_201403
    where month(time) = 3) as a group by a.d;
insert ignore into actionlog_page_pv._livescore_pv
select a.d, count(a.userid) as pv
from (
	SELECT userid, uri, date(time) as d, platform_type 
	FROM actionlog_page_pv.action_livescore_201404
    where month(time) = 4) as a group by a.d;
insert ignore into actionlog_page_pv._livescore_pv
select a.d, count(a.userid) as pv
from (
	SELECT userid, uri, date(time) as d, platform_type 
	FROM actionlog_page_pv.action_livescore_201405
    where month(time) = 5) as a group by a.d;
insert ignore into actionlog_page_pv._livescore_pv
select a.d, count(a.userid) as pv
from (
	SELECT userid, uri, date(time) as d, platform_type 
	FROM actionlog_page_pv.action_livescore_201406
	where month(time) = 6) as a group by a.d;
insert ignore into actionlog_page_pv._livescore_pv
select a.d, count(a.userid) as pv
from (
	SELECT userid, uri, date(time) as d, platform_type 
	FROM actionlog_page_pv.action_livescore_201407
    where month(time) = 7) as a group by a.d;
insert ignore into actionlog_page_pv._livescore_pv
select a.d, count(a.userid) as pv
from (
	SELECT userid, uri, date(time) as d, platform_type 
	FROM actionlog_page_pv.action_livescore_201408
    where month(time) = 8) as a group by a.d;
insert ignore into actionlog_page_pv._livescore_pv
select a.d, count(a.userid) as pv
from (
	SELECT userid, uri, date(time) as d, platform_type 
	FROM actionlog_page_pv.action_livescore_201409
    where month(time) = 9) as a group by a.d;
insert ignore into actionlog_page_pv._livescore_pv
select a.d, count(a.userid) as pv
from (
	SELECT userid, uri, date(time) as d, platform_type 
	FROM actionlog_page_pv.action_livescore_201410
    where month(time) = 10) as a group by a.d;
insert ignore into actionlog_page_pv._livescore_pv
select a.d, count(a.userid) as pv
from (
	SELECT userid, uri, date(time) as d, platform_type 
	FROM actionlog_page_pv.action_livescore_201411
    where month(time) = 11) as a group by a.d;