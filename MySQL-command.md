How to find the mysql data directory
------------------------------------
the command line:
```sh
mysql -uUSER -p -e 'SHOW VARIABLES WHERE Variable_Name LIKE "%dir"'
```
Output (on Linux):
```sh
+-----------------------------------------+----------------------------+
| Variable_name                           | Value                      |
+-----------------------------------------+----------------------------+
| basedir                                 | /usr                       |
| binlog_direct_non_transactional_updates | OFF                        |
| character_sets_dir                      | /usr/share/mysql/charsets/ |
| datadir                                 | /var/lib/mysql/            |
| innodb_data_home_dir                    |                            |
| innodb_log_group_home_dir               | ./                         |
| innodb_max_dirty_pages_pct              | 75                         |
| lc_messages_dir                         | /usr/share/mysql/          |
| plugin_dir                              | /usr/lib/mysql/plugin/     |
| slave_load_tmpdir                       | /tmp                       |
| tmpdir                                  | /tmp                       |
+-----------------------------------------+----------------------------+
```
> ref.
> - http://stackoverflow.com/questions/17968287/how-to-find-the-mysql-data-directory-from-command-line-in-windows
> - http://stackoverflow.com/questions/1795176/how-to-change-mysql-data-directory
