My mysql setting
================



mysqld
------
```?
[mysqld]
port                            = 3306
max_allowed_packet              = 34M
interactive_timeout             = 86400
wait_timeout                    = 86400
default-storage-engine          = MyISAM
default_tmp_storage_engine      = MyISAM

#bulk_insert_buffer_size         = 512M
#key_buffer_size                 = 512M
#innodb_buffer_pool_size         = 512M
#innodb_log_buffer_size          = 16M
#innodb_additional_mem_pool_size = 40M
#myisam_sort_buffer_size         = 256M

bulk_insert_buffer_size         = 512M
key_buffer_size                 = 512M
innodb_buffer_pool_size         = 512M
innodb_log_buffer_size          = 16M
innodb_additional_mem_pool_size = 40M
myisam_sort_buffer_size         = 256M

#query_cache_limit               = 10M
#query_cache_size                = 150M
#read_buffer_size                = 20M
#sort_buffer_size                = 128M
#table_cache                    = 256
#thread_cache_size              = 128
#thread_stack                   = 327680
#tmp_table_size                 = 41943040

query_cache_limit               = 50M
query_cache_size                = 1000M
read_buffer_size                = 20M
sort_buffer_size                = 128M

expire_logs_days                = 2
max_binlog_size                 = 100M
```
