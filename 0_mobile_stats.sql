# create database mobilestats;

CREATE TABLE mobilestats.our_devices
( `device`  VARCHAR(100) NOT NULL , 
  `brand`   VARCHAR(30) NOT NULL , 
  `own`     VARCHAR(10) NOT NULL ,
  `screen`  VARCHAR(10) NOT NULL ,
  `w`     int(10) NOT NULL ,
  `l`     int(10) NOT NULL ,
  `r`     double(10,2) NOT NULL
) ENGINE = MyISAM CHARACTER SET utf8 COLLATE utf8_general_ci;

insert into mobilestats.our_devices (device, brand, own, screen, w, l, r) values 
        ('HTC One 801e One','HTC','有','1080x1776','1080','1776',' 1.64 '),
        ('Samsung GT-I9300 Galaxy S III','Samsung','有','720x1280','720','1280',' 1.78 '),
        ('Samsung GT-N7100 Galaxy Note II','Samsung','有','720x1280','720','1280',' 1.78 '),
        ('Samsung SM-N900T Galaxy Note 3','Samsung','有','1080x1920','1080','1920',' 1.78 '),
        ('Samsung SM-N9005 Galaxy Note 3','Samsung','有','1080x1920','1080','1920',' 1.78 '),
        ('Samsung SM-N900 Galaxy Note 3','Samsung','有','1080x1920','1080','1920',' 1.78 '),
        ('Xiaomi MI 2S','Xiaomi','有','720x1280','720','1280',' 1.78 '),
        ('Samsung GT-N7000 Galaxy Note','Samsung','有','800x1280','800','1280',' 1.60 '),
        ('Sony D6653 Xperia Z3','Sony','有','1080x1776','1080','1776',' 1.64 '),
        ('Asus Tooj','Asus','有','720x1280','720','1280',' 1.78 '),
        ('HTC One 801e One','HTC','有','1080x1920','1080','1920',' 1.78 '),
        ('Samsung GT-I9103 Galaxy SII','Samsung','有','480x800','480','800',' 1.67 '),
        ('HTC A9191 Desire HD','HTC','有','480x800','480','800',' 1.67 '),
        ('LG D855 G3','LG','有','1440x2392','1440','2392',' 1.66 ');
        
create table mobilestats.our_devices_screen engine = myisam
SELECT screen, (case when (screen is not null) then '有' else '' end) as own
FROM mobilestats.our_devices
group by screen;

create table mobilestats.our_devices_ratio engine = myisam
SELECT r, (case when (r is not null) then '有' else '' end) as own
FROM mobilestats.our_devices
group by r;
        







CREATE TABLE mobilestats.ga_201706
( `device`   VARCHAR(100) NOT NULL , 
  `screen`   VARCHAR(30) NOT NULL , 
  `sessions` int(11) NOT NULL 
) ENGINE = MyISAM CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE TABLE mobilestats.ga_201707
( `device`   VARCHAR(100) NOT NULL , 
  `screen`   VARCHAR(30) NOT NULL , 
  `sessions` int(11) NOT NULL 
) ENGINE = MyISAM CHARACTER SET utf8 COLLATE utf8_general_ci;
drop table if exists mobilestats.ga_201708;
CREATE TABLE mobilestats.ga_201708
( `device`   VARCHAR(200) NOT NULL , 
  `screen`   VARCHAR(50) NOT NULL , 
  `sessions` int(13) NOT NULL 
) ENGINE = MyISAM CHARACTER SET utf8 COLLATE utf8_general_ci;
drop table if exists mobilestats.ga_201709;
CREATE TABLE mobilestats.ga_201709
( `device`   VARCHAR(200) NOT NULL , 
  `screen`   VARCHAR(50) NOT NULL , 
  `sessions` int(13) NOT NULL 
) ENGINE = MyISAM CHARACTER SET utf8 COLLATE utf8_general_ci;
drop table if exists mobilestats.ga_201710;
CREATE TABLE mobilestats.ga_201710
( `device`   VARCHAR(200) NOT NULL , 
  `screen`   VARCHAR(50) NOT NULL , 
  `sessions` int(13) NOT NULL 
) ENGINE = MyISAM CHARACTER SET utf8 COLLATE utf8_general_ci;
drop table if exists mobilestats.ga_201711;
CREATE TABLE mobilestats.ga_201711
( `device`   VARCHAR(200) NOT NULL , 
  `screen`   VARCHAR(50) NOT NULL , 
  `sessions` int(13) NOT NULL 
) ENGINE = MyISAM CHARACTER SET utf8 COLLATE utf8_general_ci;


LOAD DATA INFILE 'C:/Users/eddy/downloads/ga_201706.csv' 
INTO TABLE `mobilestats`.`ga_201706`  
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
LOAD DATA INFILE 'C:/Users/eddy/downloads/ga_201707.csv' 
INTO TABLE `mobilestats`.`ga_201707`  
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
LOAD DATA INFILE 'C:/Users/eddy/downloads/ga_201708.csv' 
INTO TABLE `mobilestats`.`ga_201708`  
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
LOAD DATA INFILE 'C:/Users/eddy/downloads/ga_201709.csv' 
INTO TABLE `mobilestats`.`ga_201709`  
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
LOAD DATA INFILE 'C:/Users/eddy/downloads/ga_201710.csv' 
INTO TABLE `mobilestats`.`ga_201710`  
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
LOAD DATA INFILE 'C:/Users/eddy/downloads/ga_201711.csv' 
INTO TABLE `mobilestats`.`ga_201711`  
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;






drop table if exists mobilestats._ga_201706_1; 
create table mobilestats._ga_201706_1 engine = myisam
select  a.month, a.device, a.brand, a.screen, a.w, a.l, round((a.l/a.w),2) as r, a.sessions
from (
    SELECT (case when (device is not null) then '2017_06' else '' end) as month, device, 
            substr(device,1,locate(' ', device)-1) as brand, screen, 
            substr(screen,1,locate('x', screen)-1) as w, 
            substr(screen,locate('x', screen)+1,length(screen)) as l,sessions 
    FROM mobilestats.ga_201706
    WHERE device <> '(not set)') as a;
drop table if exists mobilestats._ga_201707_1;   
create table mobilestats._ga_201707_1 engine = myisam
select  a.month, a.device, a.brand, a.screen, a.w, a.l, round((a.l/a.w),2) as r, a.sessions
from (
    SELECT (case when (device is not null) then '2017_07' else '' end) as month, device, 
            substr(device,1,locate(' ', device)-1) as brand, screen, 
            substr(screen,1,locate('x', screen)-1) as w, 
            substr(screen,locate('x', screen)+1,length(screen)) as l,sessions 
    FROM mobilestats.ga_201707
    WHERE device <> '(not set)') as a;
drop table if exists mobilestats._ga_201708_1;   
create table mobilestats._ga_201708_1 engine = myisam
select  a.month, a.device, a.brand, a.screen, a.w, a.l, round((a.l/a.w),2) as r, a.sessions
from (
    SELECT (case when (device is not null) then '2017_08' else '' end) as month, device, 
            substr(device,1,locate(' ', device)-1) as brand, screen, 
            substr(screen,1,locate('x', screen)-1) as w, 
            substr(screen,locate('x', screen)+1,length(screen)) as l,sessions 
    FROM mobilestats.ga_201708
    WHERE device <> '(not set)') as a;
drop table if exists mobilestats._ga_201709_1;   
create table mobilestats._ga_201709_1 engine = myisam
select  a.month, a.device, a.brand, a.screen, a.w, a.l, round((a.l/a.w),2) as r, a.sessions
from (
    SELECT (case when (device is not null) then '2017_09' else '' end) as month, device, 
            substr(device,1,locate(' ', device)-1) as brand, screen, 
            substr(screen,1,locate('x', screen)-1) as w, 
            substr(screen,locate('x', screen)+1,length(screen)) as l,sessions 
    FROM mobilestats.ga_201709
    WHERE device <> '(not set)') as a;
drop table if exists mobilestats._ga_201710_1;   
create table mobilestats._ga_201710_1 engine = myisam
select  a.month, a.device, a.brand, a.screen, a.w, a.l, round((a.l/a.w),2) as r, a.sessions
from (
    SELECT (case when (device is not null) then '2017_10' else '' end) as month, device, 
            substr(device,1,locate(' ', device)-1) as brand, screen, 
            substr(screen,1,locate('x', screen)-1) as w, 
            substr(screen,locate('x', screen)+1,length(screen)) as l,sessions 
    FROM mobilestats.ga_201710
    WHERE device <> '(not set)') as a;
drop table if exists mobilestats._ga_201711_1;   
create table mobilestats._ga_201711_1 engine = myisam
select  a.month, a.device, a.brand, a.screen, a.w, a.l, round((a.l/a.w),2) as r, a.sessions
from (
    SELECT (case when (device is not null) then '2017_11' else '' end) as month, device, 
            substr(device,1,locate(' ', device)-1) as brand, screen, 
            substr(screen,1,locate('x', screen)-1) as w, 
            substr(screen,locate('x', screen)+1,length(screen)) as l,sessions 
    FROM mobilestats.ga_201711
    WHERE device <> '(not set)') as a;





drop table if exists mobilestats._ga_201706_2;
create table mobilestats._ga_201706_2 engine = myisam
select e.month, e.device, e.brand, e.own, e.screen, e.w, e.l, e.r, e.inc_screen, f.own as inc_ratio, e.sessions
from (
    select c.month, c.device, c.own, c.brand, c.screen, c.w, c.l, c.r, d.own as inc_screen ,c.sessions
    from (
        SELECT a.month, a.device, b.own, a.brand, a.screen, a.w, a.l, a.r, a.sessions 
        FROM mobilestats._ga_201706_1 a left join mobilestats.our_devices b on a.device = b.device) as c 
    left join mobilestats.our_devices_screen as d on c.screen  = d.screen) as e
left join mobilestats.our_devices_ratio f on e.r = f.r
order by e.sessions desc; 

drop table if exists mobilestats._ga_201707_2;
create table mobilestats._ga_201707_2 engine = myisam
select e.month, e.device, e.brand, e.own, e.screen, e.w, e.l, e.r, e.inc_screen, f.own as inc_ratio, e.sessions
from (
    select c.month, c.device, c.own, c.brand, c.screen, c.w, c.l, c.r, d.own as inc_screen ,c.sessions
    from (
        SELECT a.month, a.device, b.own, a.brand, a.screen, a.w, a.l, a.r, a.sessions 
        FROM mobilestats._ga_201707_1 a left join mobilestats.our_devices b on a.device = b.device) as c 
    left join mobilestats.our_devices_screen as d on c.screen  = d.screen) as e
left join mobilestats.our_devices_ratio f on e.r = f.r
order by e.sessions desc; 

drop table if exists mobilestats._ga_201708_2;
create table mobilestats._ga_201708_2 engine = myisam
select e.month, e.device, e.brand, e.own, e.screen, e.w, e.l, e.r, e.inc_screen, f.own as inc_ratio, e.sessions
from (
    select c.month, c.device, c.own, c.brand, c.screen, c.w, c.l, c.r, d.own as inc_screen ,c.sessions
    from (
        SELECT a.month, a.device, b.own, a.brand, a.screen, a.w, a.l, a.r, a.sessions 
        FROM mobilestats._ga_201708_1 a left join mobilestats.our_devices b on a.device = b.device) as c 
    left join mobilestats.our_devices_screen as d on c.screen  = d.screen) as e
left join mobilestats.our_devices_ratio f on e.r = f.r
order by e.sessions desc; 

drop table if exists mobilestats._ga_201709_2;
create table mobilestats._ga_201709_2 engine = myisam
select e.month, e.device, e.brand, e.own, e.screen, e.w, e.l, e.r, e.inc_screen, f.own as inc_ratio, e.sessions
from (
    select c.month, c.device, c.own, c.brand, c.screen, c.w, c.l, c.r, d.own as inc_screen ,c.sessions
    from (
        SELECT a.month, a.device, b.own, a.brand, a.screen, a.w, a.l, a.r, a.sessions 
        FROM mobilestats._ga_201709_1 a left join mobilestats.our_devices b on a.device = b.device) as c 
    left join mobilestats.our_devices_screen as d on c.screen  = d.screen) as e
left join mobilestats.our_devices_ratio f on e.r = f.r
order by e.sessions desc; 

drop table if exists mobilestats._ga_201710_2;
create table mobilestats._ga_201710_2 engine = myisam
select e.month, e.device, e.brand, e.own, e.screen, e.w, e.l, e.r, e.inc_screen, f.own as inc_ratio, e.sessions
from (
    select c.month, c.device, c.own, c.brand, c.screen, c.w, c.l, c.r, d.own as inc_screen ,c.sessions
    from (
        SELECT a.month, a.device, b.own, a.brand, a.screen, a.w, a.l, a.r, a.sessions 
        FROM mobilestats._ga_201710_1 a left join mobilestats.our_devices b on a.device = b.device) as c 
    left join mobilestats.our_devices_screen as d on c.screen  = d.screen) as e
left join mobilestats.our_devices_ratio f on e.r = f.r
order by e.sessions desc;

drop table if exists mobilestats._ga_201711_2;
create table mobilestats._ga_201711_2 engine = myisam
select e.month, e.device, e.brand, e.own, e.screen, e.w, e.l, e.r, e.inc_screen, f.own as inc_ratio, e.sessions
from (
    select c.month, c.device, c.own, c.brand, c.screen, c.w, c.l, c.r, d.own as inc_screen ,c.sessions
    from (
        SELECT a.month, a.device, b.own, a.brand, a.screen, a.w, a.l, a.r, a.sessions 
        FROM mobilestats._ga_201711_1 a left join mobilestats.our_devices b on a.device = b.device) as c 
    left join mobilestats.our_devices_screen as d on c.screen  = d.screen) as e
left join mobilestats.our_devices_ratio f on e.r = f.r
order by e.sessions desc;






drop table if exists mobilestats._ga_201706_3;
create table mobilestats._ga_201706_3 engine = myisam
SELECT * 
FROM mobilestats._ga_201706_2
group by device, screen, sessions
order by sessions desc;
drop table if exists mobilestats._ga_201707_3;
create table mobilestats._ga_201707_3 engine = myisam
SELECT * 
FROM mobilestats._ga_201707_2
group by device, screen, sessions
order by sessions desc;
drop table if exists mobilestats._ga_201708_3;
create table mobilestats._ga_201708_3 engine = myisam
SELECT * 
FROM mobilestats._ga_201708_2
group by device, screen, sessions
order by sessions desc;
drop table if exists mobilestats._ga_201709_3;
create table mobilestats._ga_201709_3 engine = myisam
SELECT * 
FROM mobilestats._ga_201709_2
group by device, screen, sessions
order by sessions desc;
drop table if exists mobilestats._ga_201710_3;
create table mobilestats._ga_201710_3 engine = myisam
SELECT * 
FROM mobilestats._ga_201710_2
group by device, screen, sessions
order by sessions desc;
drop table if exists mobilestats._ga_201711_3;
create table mobilestats._ga_201711_3 engine = myisam
SELECT * 
FROM mobilestats._ga_201711_2
group by device, screen, sessions
order by sessions desc;


drop table if exists mobilestats._ga_all;
create table mobilestats._ga_all engine = myisam SELECT * FROM mobilestats._ga_201701_3;
insert ignore into mobilestats._ga_all SELECT * FROM mobilestats._ga_201702_3;
insert ignore into mobilestats._ga_all SELECT * FROM mobilestats._ga_201703_3;
insert ignore into mobilestats._ga_all SELECT * FROM mobilestats._ga_201704_3;
insert ignore into mobilestats._ga_all SELECT * FROM mobilestats._ga_201705_3;
insert ignore into mobilestats._ga_all SELECT * FROM mobilestats._ga_201706_3;
insert ignore into mobilestats._ga_all SELECT * FROM mobilestats._ga_201707_3;
insert ignore into mobilestats._ga_all SELECT * FROM mobilestats._ga_201708_3;
insert ignore into mobilestats._ga_all SELECT * FROM mobilestats._ga_201709_3;
insert ignore into mobilestats._ga_all SELECT * FROM mobilestats._ga_201710_3;
insert ignore into mobilestats._ga_all SELECT * FROM mobilestats._ga_201711_3;


