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
        

CREATE TABLE mobilestats.ga_201601
( `device`   VARCHAR(100) NOT NULL , 
  `screen`   VARCHAR(30) NOT NULL , 
  `sessions` int(11) NOT NULL 
) ENGINE = MyISAM CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE TABLE mobilestats.ga_201602
( `device`   VARCHAR(100) NOT NULL , 
  `screen`   VARCHAR(30) NOT NULL , 
  `sessions` int(11) NOT NULL 
) ENGINE = MyISAM CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE TABLE mobilestats.ga_201603
( `device`   VARCHAR(100) NOT NULL , 
  `screen`   VARCHAR(30) NOT NULL , 
  `sessions` int(11) NOT NULL 
) ENGINE = MyISAM CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE TABLE mobilestats.ga_201604
( `device`   VARCHAR(100) NOT NULL , 
  `screen`   VARCHAR(30) NOT NULL , 
  `sessions` int(11) NOT NULL 
) ENGINE = MyISAM CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE TABLE mobilestats.ga_201605
( `device`   VARCHAR(100) NOT NULL , 
  `screen`   VARCHAR(30) NOT NULL , 
  `sessions` int(11) NOT NULL 
) ENGINE = MyISAM CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE TABLE mobilestats.ga_201606
( `device`   VARCHAR(100) NOT NULL , 
  `screen`   VARCHAR(30) NOT NULL , 
  `sessions` int(11) NOT NULL 
) ENGINE = MyISAM CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE TABLE mobilestats.ga_201607
( `device`   VARCHAR(100) NOT NULL , 
  `screen`   VARCHAR(30) NOT NULL , 
  `sessions` int(11) NOT NULL 
) ENGINE = MyISAM CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE TABLE mobilestats.ga_201608
( `device`   VARCHAR(100) NOT NULL , 
  `screen`   VARCHAR(30) NOT NULL , 
  `sessions` int(11) NOT NULL 
) ENGINE = MyISAM CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE TABLE mobilestats.ga_201609
( `device`   VARCHAR(100) NOT NULL , 
  `screen`   VARCHAR(30) NOT NULL , 
  `sessions` int(11) NOT NULL 
) ENGINE = MyISAM CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE TABLE mobilestats.ga_201610
( `device`   VARCHAR(100) NOT NULL , 
  `screen`   VARCHAR(30) NOT NULL , 
  `sessions` int(11) NOT NULL 
) ENGINE = MyISAM CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE TABLE mobilestats.ga_201611
( `device`   VARCHAR(100) NOT NULL , 
  `screen`   VARCHAR(30) NOT NULL , 
  `sessions` int(11) NOT NULL 
) ENGINE = MyISAM CHARACTER SET utf8 COLLATE utf8_general_ci;

CREATE TABLE mobilestats.ga_201612
( `device`   VARCHAR(100) NOT NULL , 
  `screen`   VARCHAR(30) NOT NULL , 
  `sessions` int(11) NOT NULL 
) ENGINE = MyISAM CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE TABLE mobilestats.ga_201701
( `device`   VARCHAR(100) NOT NULL , 
  `screen`   VARCHAR(30) NOT NULL , 
  `sessions` int(11) NOT NULL 
) ENGINE = MyISAM CHARACTER SET utf8 COLLATE utf8_general_ci;


LOAD DATA INFILE 'C:/Users/eddy/Desktop/ga_201601.csv' 
INTO TABLE `mobilestats`.`ga_201601`  
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
LOAD DATA INFILE 'C:/Users/eddy/Desktop/ga_201602.csv' 
INTO TABLE `mobilestats`.`ga_201602`  
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
LOAD DATA INFILE 'C:/Users/eddy/Desktop/ga_201603.csv' 
INTO TABLE `mobilestats`.`ga_201603`  
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
LOAD DATA INFILE 'C:/Users/eddy/Desktop/ga_201604.csv' 
INTO TABLE `mobilestats`.`ga_201604`  
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
LOAD DATA INFILE 'C:/Users/eddy/Desktop/ga_201605.csv' 
INTO TABLE `mobilestats`.`ga_201605`  
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
LOAD DATA INFILE 'C:/Users/eddy/Desktop/201606.csv' 
INTO TABLE `mobilestats`.`ga_201606`  
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
LOAD DATA INFILE 'C:/Users/eddy/Desktop/201607.csv' 
INTO TABLE `mobilestats`.`ga_201607`  
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
LOAD DATA INFILE 'C:/Users/eddy/Desktop/201608.csv' 
INTO TABLE `mobilestats`.`ga_201608`  
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
LOAD DATA INFILE 'C:/Users/eddy/Desktop/201609.csv' 
INTO TABLE `mobilestats`.`ga_201609`  
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
LOAD DATA INFILE 'C:/Users/eddy/Desktop/ga_201610.csv' 
INTO TABLE `mobilestats`.`ga_201610`  
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
LOAD DATA INFILE 'C:/Users/eddy/Desktop/ga_201611.csv' 
INTO TABLE `mobilestats`.`ga_201611`  
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
LOAD DATA INFILE 'C:/Users/eddy/Desktop/ga_201612.csv' 
INTO TABLE `mobilestats`.`ga_201612`  
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
LOAD DATA INFILE 'C:/Users/eddy/Desktop/ga_201701.csv' 
INTO TABLE `mobilestats`.`ga_201701`  
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;





create table mobilestats._ga_201601_1 engine = myisam
select  a.month, a.device, a.brand, a.screen, a.w, a.l, round((a.l/a.w),2) as r, a.sessions
from (
    SELECT (case when (device is not null) then '2016_01' else '' end) as month, device, 
            substr(device,1,locate(' ', device)-1) as brand, screen, 
            substr(screen,1,locate('x', screen)-1) as w, 
            substr(screen,locate('x', screen)+1,length(screen)) as l,sessions 
    FROM mobilestats.ga_201601
    WHERE device <> '(not set)') as a;
create table mobilestats._ga_201602_1 engine = myisam
select  a.month, a.device, a.brand, a.screen, a.w, a.l, round((a.l/a.w),2) as r, a.sessions
from (
    SELECT (case when (device is not null) then '2016_02' else '' end) as month, device, 
            substr(device,1,locate(' ', device)-1) as brand, screen, 
            substr(screen,1,locate('x', screen)-1) as w, 
            substr(screen,locate('x', screen)+1,length(screen)) as l,sessions 
    FROM mobilestats.ga_201602
    WHERE device <> '(not set)') as a;
create table mobilestats._ga_201603_1 engine = myisam
select  a.month, a.device, a.brand, a.screen, a.w, a.l, round((a.l/a.w),2) as r, a.sessions
from (
    SELECT (case when (device is not null) then '2016_03' else '' end) as month, device, 
            substr(device,1,locate(' ', device)-1) as brand, screen, 
            substr(screen,1,locate('x', screen)-1) as w, 
            substr(screen,locate('x', screen)+1,length(screen)) as l,sessions 
    FROM mobilestats.ga_201603
    WHERE device <> '(not set)') as a;
create table mobilestats._ga_201604_1 engine = myisam
select  a.month, a.device, a.brand, a.screen, a.w, a.l, round((a.l/a.w),2) as r, a.sessions
from (
    SELECT (case when (device is not null) then '2016_04' else '' end) as month, device, 
            substr(device,1,locate(' ', device)-1) as brand, screen, 
            substr(screen,1,locate('x', screen)-1) as w, 
            substr(screen,locate('x', screen)+1,length(screen)) as l,sessions 
    FROM mobilestats.ga_201604
    WHERE device <> '(not set)') as a;
create table mobilestats._ga_201605_1 engine = myisam
select  a.month, a.device, a.brand, a.screen, a.w, a.l, round((a.l/a.w),2) as r, a.sessions
from (
    SELECT (case when (device is not null) then '2016_05' else '' end) as month, device, 
            substr(device,1,locate(' ', device)-1) as brand, screen, 
            substr(screen,1,locate('x', screen)-1) as w, 
            substr(screen,locate('x', screen)+1,length(screen)) as l,sessions 
    FROM mobilestats.ga_201605
    WHERE device <> '(not set)') as a;
    
create table mobilestats._ga_201606_1 engine = myisam
select  a.month, a.device, a.brand, a.screen, a.w, a.l, round((a.l/a.w),2) as r, a.sessions
from (
    SELECT (case when (device is not null) then '2016_06' else '' end) as month, device, 
            substr(device,1,locate(' ', device)-1) as brand, screen, 
            substr(screen,1,locate('x', screen)-1) as w, 
            substr(screen,locate('x', screen)+1,length(screen)) as l,sessions 
    FROM mobilestats.ga_201606
    WHERE device <> '(not set)') as a;
create table mobilestats._ga_201607_1 engine = myisam
select  a.month, a.device, a.brand, a.screen, a.w, a.l, round((a.l/a.w),2) as r, a.sessions
from (
    SELECT (case when (device is not null) then '2016_07' else '' end) as month, device, 
            substr(device,1,locate(' ', device)-1) as brand, screen, 
            substr(screen,1,locate('x', screen)-1) as w, 
            substr(screen,locate('x', screen)+1,length(screen)) as l,sessions 
    FROM mobilestats.ga_201607
    WHERE device <> '(not set)') as a;
create table mobilestats._ga_201608_1 engine = myisam
select  a.month, a.device, a.brand, a.screen, a.w, a.l, round((a.l/a.w),2) as r, a.sessions
from (
    SELECT (case when (device is not null) then '2016_08' else '' end) as month, device, 
            substr(device,1,locate(' ', device)-1) as brand, screen, 
            substr(screen,1,locate('x', screen)-1) as w, 
            substr(screen,locate('x', screen)+1,length(screen)) as l,sessions 
    FROM mobilestats.ga_201608
    WHERE device <> '(not set)') as a;
create table mobilestats._ga_201609_1 engine = myisam
select  a.month, a.device, a.brand, a.screen, a.w, a.l, round((a.l/a.w),2) as r, a.sessions
from (
    SELECT (case when (device is not null) then '2016_09' else '' end) as month, device, 
            substr(device,1,locate(' ', device)-1) as brand, screen, 
            substr(screen,1,locate('x', screen)-1) as w, 
            substr(screen,locate('x', screen)+1,length(screen)) as l,sessions 
    FROM mobilestats.ga_201609
    WHERE device <> '(not set)') as a;
    
create table mobilestats._ga_201610_1 engine = myisam
select  a.month, a.device, a.brand, a.screen, a.w, a.l, round((a.l/a.w),2) as r, a.sessions
from (
    SELECT (case when (device is not null) then '2016_10' else '' end) as month, device, 
            substr(device,1,locate(' ', device)-1) as brand, screen, 
            substr(screen,1,locate('x', screen)-1) as w, 
            substr(screen,locate('x', screen)+1,length(screen)) as l,sessions 
    FROM mobilestats.ga_201610
    WHERE device <> '(not set)') as a;
create table mobilestats._ga_201611_1 engine = myisam
select  a.month, a.device, a.brand, a.screen, a.w, a.l, round((a.l/a.w),2) as r, a.sessions
from (
    SELECT (case when (device is not null) then '2016_11' else '' end) as month, device, 
            substr(device,1,locate(' ', device)-1) as brand, screen, 
            substr(screen,1,locate('x', screen)-1) as w, 
            substr(screen,locate('x', screen)+1,length(screen)) as l,sessions 
    FROM mobilestats.ga_201611
    WHERE device <> '(not set)') as a;
drop table if exists mobilestats._ga_201612_1;
create table mobilestats._ga_201612_1 engine = myisam
select  a.month, a.device, a.brand, a.screen, a.w, a.l, round((a.l/a.w),2) as r, a.sessions
from (
    SELECT (case when (device is not null) then '2016_12' else '' end) as month, device, 
            substr(device,1,locate(' ', device)-1) as brand, screen, 
            substr(screen,1,locate('x', screen)-1) as w, 
            substr(screen,locate('x', screen)+1,length(screen)) as l,sessions 
    FROM mobilestats.ga_201612
    WHERE device <> '(not set)') as a;
drop table if exists mobilestats._ga_201701_1;
create table mobilestats._ga_201701_1 engine = myisam
select  a.month, a.device, a.brand, a.screen, a.w, a.l, round((a.l/a.w),2) as r, a.sessions
from (
    SELECT (case when (device is not null) then '2017_01' else '' end) as month, device, 
            substr(device,1,locate(' ', device)-1) as brand, screen, 
            substr(screen,1,locate('x', screen)-1) as w, 
            substr(screen,locate('x', screen)+1,length(screen)) as l,sessions 
    FROM mobilestats.ga_201701
    WHERE device <> '(not set)') as a;















create table mobilestats._ga_201601_2 engine = myisam
select e.month, e.device, e.brand, e.own, e.screen, e.w, e.l, e.r, e.inc_screen, f.own as inc_ratio, e.sessions
from (
    select c.month, c.device, c.own, c.brand, c.screen, c.w, c.l, c.r, d.own as inc_screen ,c.sessions
    from (
        SELECT a.month, a.device, b.own, a.brand, a.screen, a.w, a.l, a.r, a.sessions 
        FROM mobilestats._ga_201601_1 a left join mobilestats.our_devices b on a.device = b.device) as c 
    left join mobilestats.our_devices_screen as d on c.screen  = d.screen) as e
left join mobilestats.our_devices_ratio f on e.r = f.r
order by e.sessions desc; 

create table mobilestats._ga_201602_2 engine = myisam
select e.month, e.device, e.brand, e.own, e.screen, e.w, e.l, e.r, e.inc_screen, f.own as inc_ratio, e.sessions
from (
    select c.month, c.device, c.own, c.brand, c.screen, c.w, c.l, c.r, d.own as inc_screen ,c.sessions
    from (
        SELECT a.month, a.device, b.own, a.brand, a.screen, a.w, a.l, a.r, a.sessions 
        FROM mobilestats._ga_201602_1 a left join mobilestats.our_devices b on a.device = b.device) as c 
    left join mobilestats.our_devices_screen as d on c.screen  = d.screen) as e
left join mobilestats.our_devices_ratio f on e.r = f.r
order by e.sessions desc; 

create table mobilestats._ga_201603_2 engine = myisam
select e.month, e.device, e.brand, e.own, e.screen, e.w, e.l, e.r, e.inc_screen, f.own as inc_ratio, e.sessions
from (
    select c.month, c.device, c.own, c.brand, c.screen, c.w, c.l, c.r, d.own as inc_screen ,c.sessions
    from (
        SELECT a.month, a.device, b.own, a.brand, a.screen, a.w, a.l, a.r, a.sessions 
        FROM mobilestats._ga_201603_1 a left join mobilestats.our_devices b on a.device = b.device) as c 
    left join mobilestats.our_devices_screen as d on c.screen  = d.screen) as e
left join mobilestats.our_devices_ratio f on e.r = f.r
order by e.sessions desc; 

create table mobilestats._ga_201604_2 engine = myisam
select e.month, e.device, e.brand, e.own, e.screen, e.w, e.l, e.r, e.inc_screen, f.own as inc_ratio, e.sessions
from (
    select c.month, c.device, c.own, c.brand, c.screen, c.w, c.l, c.r, d.own as inc_screen ,c.sessions
    from (
        SELECT a.month, a.device, b.own, a.brand, a.screen, a.w, a.l, a.r, a.sessions 
        FROM mobilestats._ga_201604_1 a left join mobilestats.our_devices b on a.device = b.device) as c 
    left join mobilestats.our_devices_screen as d on c.screen  = d.screen) as e
left join mobilestats.our_devices_ratio f on e.r = f.r
order by e.sessions desc; 

create table mobilestats._ga_201605_2 engine = myisam
select e.month, e.device, e.brand, e.own, e.screen, e.w, e.l, e.r, e.inc_screen, f.own as inc_ratio, e.sessions
from (
    select c.month, c.device, c.own, c.brand, c.screen, c.w, c.l, c.r, d.own as inc_screen ,c.sessions
    from (
        SELECT a.month, a.device, b.own, a.brand, a.screen, a.w, a.l, a.r, a.sessions 
        FROM mobilestats._ga_201605_1 a left join mobilestats.our_devices b on a.device = b.device) as c 
    left join mobilestats.our_devices_screen as d on c.screen  = d.screen) as e
left join mobilestats.our_devices_ratio f on e.r = f.r
order by e.sessions desc; 

create table mobilestats._ga_201606_2 engine = myisam
select e.month, e.device, e.brand, e.own, e.screen, e.w, e.l, e.r, e.inc_screen, f.own as inc_ratio, e.sessions
from (
    select c.month, c.device, c.own, c.brand, c.screen, c.w, c.l, c.r, d.own as inc_screen ,c.sessions
    from (
        SELECT a.month, a.device, b.own, a.brand, a.screen, a.w, a.l, a.r, a.sessions 
        FROM mobilestats._ga_201606_1 a left join mobilestats.our_devices b on a.device = b.device) as c 
    left join mobilestats.our_devices_screen as d on c.screen  = d.screen) as e
left join mobilestats.our_devices_ratio f on e.r = f.r
order by e.sessions desc; 

create table mobilestats._ga_201607_2 engine = myisam
select e.month, e.device, e.brand, e.own, e.screen, e.w, e.l, e.r, e.inc_screen, f.own as inc_ratio, e.sessions
from (
    select c.month, c.device, c.own, c.brand, c.screen, c.w, c.l, c.r, d.own as inc_screen ,c.sessions
    from (
        SELECT a.month, a.device, b.own, a.brand, a.screen, a.w, a.l, a.r, a.sessions 
        FROM mobilestats._ga_201607_1 a left join mobilestats.our_devices b on a.device = b.device) as c 
    left join mobilestats.our_devices_screen as d on c.screen  = d.screen) as e
left join mobilestats.our_devices_ratio f on e.r = f.r
order by e.sessions desc; 

create table mobilestats._ga_201608_2 engine = myisam
select e.month, e.device, e.brand, e.own, e.screen, e.w, e.l, e.r, e.inc_screen, f.own as inc_ratio, e.sessions
from (
    select c.month, c.device, c.own, c.brand, c.screen, c.w, c.l, c.r, d.own as inc_screen ,c.sessions
    from (
        SELECT a.month, a.device, b.own, a.brand, a.screen, a.w, a.l, a.r, a.sessions 
        FROM mobilestats._ga_201608_1 a left join mobilestats.our_devices b on a.device = b.device) as c 
    left join mobilestats.our_devices_screen as d on c.screen  = d.screen) as e
left join mobilestats.our_devices_ratio f on e.r = f.r
order by e.sessions desc; 

create table mobilestats._ga_201609_2 engine = myisam
select e.month, e.device, e.brand, e.own, e.screen, e.w, e.l, e.r, e.inc_screen, f.own as inc_ratio, e.sessions
from (
    select c.month, c.device, c.own, c.brand, c.screen, c.w, c.l, c.r, d.own as inc_screen ,c.sessions
    from (
        SELECT a.month, a.device, b.own, a.brand, a.screen, a.w, a.l, a.r, a.sessions 
        FROM mobilestats._ga_201609_1 a left join mobilestats.our_devices b on a.device = b.device) as c 
    left join mobilestats.our_devices_screen as d on c.screen  = d.screen) as e
left join mobilestats.our_devices_ratio f on e.r = f.r
order by e.sessions desc; 

create table mobilestats._ga_201610_2 engine = myisam
select e.month, e.device, e.brand, e.own, e.screen, e.w, e.l, e.r, e.inc_screen, f.own as inc_ratio, e.sessions
from (
    select c.month, c.device, c.own, c.brand, c.screen, c.w, c.l, c.r, d.own as inc_screen ,c.sessions
    from (
        SELECT a.month, a.device, b.own, a.brand, a.screen, a.w, a.l, a.r, a.sessions 
        FROM mobilestats._ga_201610_1 a left join mobilestats.our_devices b on a.device = b.device) as c 
    left join mobilestats.our_devices_screen as d on c.screen  = d.screen) as e
left join mobilestats.our_devices_ratio f on e.r = f.r
order by e.sessions desc; 

create table mobilestats._ga_201611_2 engine = myisam
select e.month, e.device, e.brand, e.own, e.screen, e.w, e.l, e.r, e.inc_screen, f.own as inc_ratio, e.sessions
from (
    select c.month, c.device, c.own, c.brand, c.screen, c.w, c.l, c.r, d.own as inc_screen ,c.sessions
    from (
        SELECT a.month, a.device, b.own, a.brand, a.screen, a.w, a.l, a.r, a.sessions 
        FROM mobilestats._ga_201611_1 a left join mobilestats.our_devices b on a.device = b.device) as c 
    left join mobilestats.our_devices_screen as d on c.screen  = d.screen) as e
left join mobilestats.our_devices_ratio f on e.r = f.r
order by e.sessions desc; 

drop table if exists mobilestats._ga_201612_2;
create table mobilestats._ga_201612_2 engine = myisam
select e.month, e.device, e.brand, e.own, e.screen, e.w, e.l, e.r, e.inc_screen, f.own as inc_ratio, e.sessions
from (
    select c.month, c.device, c.own, c.brand, c.screen, c.w, c.l, c.r, d.own as inc_screen ,c.sessions
    from (
        SELECT a.month, a.device, b.own, a.brand, a.screen, a.w, a.l, a.r, a.sessions 
        FROM mobilestats._ga_201612_1 a left join mobilestats.our_devices b on a.device = b.device) as c 
    left join mobilestats.our_devices_screen as d on c.screen  = d.screen) as e
left join mobilestats.our_devices_ratio f on e.r = f.r
order by e.sessions desc; 
drop table if exists mobilestats._ga_201701_2;
create table mobilestats._ga_201701_2 engine = myisam
select e.month, e.device, e.brand, e.own, e.screen, e.w, e.l, e.r, e.inc_screen, f.own as inc_ratio, e.sessions
from (
    select c.month, c.device, c.own, c.brand, c.screen, c.w, c.l, c.r, d.own as inc_screen ,c.sessions
    from (
        SELECT a.month, a.device, b.own, a.brand, a.screen, a.w, a.l, a.r, a.sessions 
        FROM mobilestats._ga_201701_1 a left join mobilestats.our_devices b on a.device = b.device) as c 
    left join mobilestats.our_devices_screen as d on c.screen  = d.screen) as e
left join mobilestats.our_devices_ratio f on e.r = f.r
order by e.sessions desc; 







create table mobilestats._ga_201601_3 engine = myisam
SELECT * 
FROM mobilestats._ga_201601_2
group by device, screen, sessions
order by sessions desc;
create table mobilestats._ga_201602_3 engine = myisam
SELECT * 
FROM mobilestats._ga_201602_2
group by device, screen, sessions
order by sessions desc;
create table mobilestats._ga_201603_3 engine = myisam
SELECT * 
FROM mobilestats._ga_201603_2
group by device, screen, sessions
order by sessions desc;
create table mobilestats._ga_201604_3 engine = myisam
SELECT * 
FROM mobilestats._ga_201604_2
group by device, screen, sessions
order by sessions desc;
create table mobilestats._ga_201605_3 engine = myisam
SELECT * 
FROM mobilestats._ga_201605_2
group by device, screen, sessions
order by sessions desc;
create table mobilestats._ga_201606_3 engine = myisam
SELECT * 
FROM mobilestats._ga_201606_2
group by device, screen, sessions
order by sessions desc;
create table mobilestats._ga_201607_3 engine = myisam
SELECT * 
FROM mobilestats._ga_201607_2
group by device, screen, sessions
order by sessions desc;
create table mobilestats._ga_201608_3 engine = myisam
SELECT * 
FROM mobilestats._ga_201608_2
group by device, screen, sessions
order by sessions desc;
create table mobilestats._ga_201609_3 engine = myisam
SELECT * 
FROM mobilestats._ga_201609_2
group by device, screen, sessions
order by sessions desc;
create table mobilestats._ga_201610_3 engine = myisam
SELECT * 
FROM mobilestats._ga_201610_2
group by device, screen, sessions
order by sessions desc;
create table mobilestats._ga_201611_3 engine = myisam
SELECT * 
FROM mobilestats._ga_201611_2
group by device, screen, sessions
order by sessions desc;
drop table if exists mobilestats._ga_201612_3;
create table mobilestats._ga_201612_3 engine = myisam
SELECT * 
FROM mobilestats._ga_201612_2
group by device, screen, sessions
order by sessions desc;
drop table if exists mobilestats._ga_201701_3;
create table mobilestats._ga_201701_3 engine = myisam
SELECT * 
FROM mobilestats._ga_201701_2
group by device, screen, sessions
order by sessions desc;



drop table if exists mobilestats._ga_all;
create table mobilestats._ga_all engine = myisam SELECT * FROM mobilestats._ga_201601_3;
insert ignore into mobilestats._ga_all SELECT * FROM mobilestats._ga_201602_3;
insert ignore into mobilestats._ga_all SELECT * FROM mobilestats._ga_201603_3;
insert ignore into mobilestats._ga_all SELECT * FROM mobilestats._ga_201604_3;
insert ignore into mobilestats._ga_all SELECT * FROM mobilestats._ga_201605_3;
insert ignore into mobilestats._ga_all SELECT * FROM mobilestats._ga_201606_3;
insert ignore into mobilestats._ga_all SELECT * FROM mobilestats._ga_201607_3;
insert ignore into mobilestats._ga_all SELECT * FROM mobilestats._ga_201608_3;
insert ignore into mobilestats._ga_all SELECT * FROM mobilestats._ga_201609_3;
insert ignore into mobilestats._ga_all SELECT * FROM mobilestats._ga_201610_3;
insert ignore into mobilestats._ga_all SELECT * FROM mobilestats._ga_201611_3;
insert ignore into mobilestats._ga_all SELECT * FROM mobilestats._ga_201612_3;
insert ignore into mobilestats._ga_all SELECT * FROM mobilestats._ga_201701_3;