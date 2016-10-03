into outfile :thumbsup:
-------------------------
```sh
SELECT 'a', 'b', 'c' union (
SELECT *
into outfile 'C:/Users/eddy/Desktop/xxxxx.txt'
fields terminated by ',' enclosed by '"' lines terminated by '\r\n'
FROM plsport_playsport.xxxxx);
```

alter table
-------------------------
```sh
ALTER TABLE plsport_playsport.xxxxx CHANGE `userid` `userid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
```
```sh
ALTER TABLE plsport_playsport.xxxxx ADD INDEX (`userid`);
```
```sh
ALTER TABLE plsport_playsport.xxxxx convert to character set utf8 collate utf8_general_ci;
```
```sh
ALTER DATABASE plsport_playsport character set utf8 collate utf8_general_ci;
```

change variable name
--------------------
```sh
ALTER TABLE `questionnaire_201510061537118762_answer` CHANGE `1444116822` `q1` VARCHAR(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
```

calculate percentile in MySQL
-----------------------------
```sh
create table plsport_playsport._xxxxx engine = myisam
select userid, reply, round((cnt-rank+1)/cnt,2) as reply_percentile
from (SELECT userid, reply, @curRank := @curRank + 1 AS rank
	  FROM plsport_playsport._yyyyy, (SELECT @curRank := 0) r
	  order by reply desc) as dt,
	 (select count(distinct userid) as cnt from plsport_playsport._yyyyy) as ct;
```

calculate median in MySQL
-----------------------------------------
```
SELECT avg(t1.val) as median_val FROM (
SELECT @rownum:=@rownum+1 as `row_number`, d.val
  FROM data d,  (SELECT @rownum:=0) r
  WHERE 1
  -- put some where clause here
  ORDER BY d.val
) as t1, 
(
  SELECT count(*) as total_rows
  FROM data d
  WHERE 1
  -- put same where clause here
) as t2
WHERE 1
AND t1.row_number in ( floor((total_rows+1)/2), floor((total_rows+2)/2) );
```

Making a NULL value in a MySQL field appear as 0 / N/A
------------------------------------------------------
把NA換成0
```sh
COALESCE(valuecolumn, 0)
```
把NA換成N/A
```sh
IFNULL(valuecolumn, 'N/A')
```

use function STR_TO_DATE to convert MongeDB datetime value to MySQL
-------------------------------------------------------------------
```
DATE_ADD(STR_TO_DATE(datetime,'%Y-%m-%dT%H:%i:%s.000Z'), INTERVAL 8 HOUR) as d
```

Add Auto-Increment ID to existing table
---------------------------------------
```
ALTER TABLE db.table ADD COLUMN id INT NOT NULL auto_increment PRIMARY KEY
```

CREATE / INSERT 
---------------
```
CREATE TABLE db.table
          ( `no`            int(10) NOT NULL, 
            `which_side_win`   varchar(10) NOT NULL,
            `which_side_win_c` varchar(20) NOT NULL,
            `recentlyday`   varchar(10) NOT NULL ,
            `gametype`      int(10) NOT NULL,
            `gametype_c`    varchar(30) NOT NULL , 
            `alliance`      int(10) NOT NULL, 
            `alliance_c`    varchar(30) NOT NULL , 
            `scale_range1`  double(10,2) NOT NULL,
            `scale_range2`  double(10,2) NOT NULL,
            `total_games`   int(10) NOT NULL, 
            `win_games`     int(10) NOT NULL, 
            `win_percentage` double(10,2) NOT NULL
          ) ENGINE = MyISAM CHARACTER SET utf8 COLLATE utf8_general_ci;

INSERT INTO db.table (userid, pv1, pv2) values (' ',' ',' ');
```

PURGE BINARY LOGS Syntax
-------------------------
```sh
PURGE BINARY LOGS BEFORE '2014-12-31 00:00:00';
```

