yum install perl net-tools libncurses* libaio

 rpm -ivh *rpm --nodeps --force

```
warning: ./sql/mysql-community-client-8.0.27-1.el7.x86_64.rpm: Header V3 DSA/SHA256 Signature, key ID 5072e1f5: NOKEY
Verifying...                          ################################# [100%]
Preparing...                          ################################# [100%]
Updating / installing...
   1:mysql-community-common-8.0.27-1.e################################# [ 17%]
   2:mysql-community-libs-8.0.27-1.el7################################# [ 33%]
   3:mysql-community-client-8.0.27-1.e################################# [ 50%]
   4:mysql-community-server-8.0.27-1.e################################# [ 67%]
   5:mysql-community-devel-8.0.27-1.el################################# [ 83%]
   6:mysql-community-libs-compat-8.0.2################################# [100%]
/usr/lib/tmpfiles.d/mysql.conf:23: Line references path below legacy directory /var/run/, updating /var/run/mysqld 鈫/run/mysqld; please update the tmpfiles.d/ drop-in file accordingly.
```

修改/var/run/mysqld  - run/mysqld 

rpm -ivh compat-openssl10-1.0.2o-3.el8.x86_64.rpm



```
[root@mysql-1 weihulyp]#  grep 'temporary password' /var/log/mysqld.log
2023-09-19T09:32:08.153817Z 6 [Note] [MY-010454] [Server] A temporary password is generated for root@localhost: s3d(PDA1<Fy>
```



# 初始化  

 mysqld --initialize --lower-case-table-names=1
 chown -R mysql.mysql /var/lib/mysql
 systemctl start mysqld

 # 查看登录密码
 grep 'temporary password' /var/log/mysqld.log
 # 登录mysql修改密码
ALTER USER USER() IDENTIFIED BY 'root';
# 创建
CREATE USER 'root'@'%' IDENTIFIED BY 'root';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;

# nacos访问需要修改密码策略.
ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'root';
FLUSH PRIVILEGES;

---



# 主库执行

CREATE USER 'slave'@'10.217.2.%' IDENTIFIED BY 'repl@123456';
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'slave'@'10.217.2.%';

# 主库备份
mysqldump  --single-transaction   -A -uroot -p >all.sql
#从库执行
CHANGE MASTER TO MASTER_HOST='10.217.2.56',MASTER_PORT=3306,MASTER_USER='slave',MASTER_PASSWORD='repl@123456',MASTER_AUTO_POSITION=1,get_master_public_key=1;
宋海龙
16:43SET GLOBAL gtid_purged="5ea79e21-090d-11ee-bf21-fa163e11cb00:1-3885720";
宋海龙
16:44innodb_buffer_pool_size
宋海龙
16:44server_id = 1