
#!/bin/bash
clear
echo "========================================================================="
echo ""
echo "Mysql for Centos  Install scripts "
echo "Default Install PATH:/usr/local/mysql"
echo "========================================================================="
echo ""
echo ""

read -p "=====Press any key to start when you feel OK...====="
basedir='/usr/local/mysql'
datadir='/data/mysqldata/3306'
softdir='/data/soft'
user='mysql'
group='mysql'
logs=/tmp/auto_install_mysql_`date +%F`.log
port=3306
curDate=`date +'%Y%m%d'`
myFile=mysql-5.7.23-el7-x86_64.tar.gz

echo "`date +%F` beginning !" >>$logs
echo "********* Create User Mysql**************"
groupadd mysql
useradd -g mysql mysql
checkusr=`grep -e mysql /etc/passwd | wc -l`
if [ $checkusr -gt 0 ]
 then echo "User mysql has been created"
fi
#create mysql datadir and soft link to /home/mysql
if [ ! -d $datadir ];then
        mkdir -p /mysqldata/{3306/{data,tmp,binlog,slave,log/iblog},backup,scripts}
        chown -R mysql:mysql /mysqldata
        su - mysql -c "ln -s /mysqldata /home/mysql/mysqldata"
         echo -e "create datadir for mysql" >>$logs
fi

#Setup Ulimit
echo  "mysql soft nproc  10240" >> /etc/security/limits.conf
echo  "mysql hard nproc  16384" >> /etc/security/limits.conf
echo  "mysql soft nofile 65536" >> /etc/security/limits.conf
echo  "mysql hard nofile 65536" >> /etc/security/limits.conf 

#create mysqlsoft basedir
if [ ! -d $softdir ];then
        mkdir -p /data/soft
        chown -R mysql:mysql /data/soft
         echo -e "create basedir the mysql" >>$logs
fi

read -p "Please Upload Mysql Software(mysql-5.7.23-el7-x86_64.tar.gz) to /data/soft and Press Enter when software  uploading is done..... Thanks"
chown -R mysql:mysql /data/soft 
#Grant mysql permission to /data/soft
checkowner=`ls -l  /data | awk 'NR > 1 {print $3}' | grep -v total`
if [ "$checkowner" = "mysql" ]
then
  echo "*********/data/soft's permission was granted to mysql*********"
  echo -e "/data/soft's permission was granted to mysql after software uploaded" >>$logs
fi

install(){
cd $softdir
tar -zxvf $myFile -C /usr/local/
cd /usr/local/
ln -s mysql-5.7.23-el7-x86_64 mysql
chown -R mysql:mysql /usr/local/mysql
checkbin=`ls /usr/local/mysql | wc -l`
if [ $checkbin -gt 0 ]
 then 
echo  "Mysql Binary Sofware was installed successful" 
echo -e "Mysql Binary Sofware was installed" >>$logs
fi

su - mysql -c "touch /home/mysql/mysqldata/3306/my.cnf"
export MYSQL_PORT=${port}
## generate server id
server_id=`date +'%y%m%d%H%M'`
export MYSQL_SERVER_ID=${server_id}

cat >> /home/mysql/mysqldata/3306/my.cnf << EOF
[client]
port = 3306

#The MySQL server
[mysqld]
server_id=${MYSQL_SERVER_ID}
port = 3306
user = mysql
socket = /home/mysql/mysqldata/3306/mysql.sock
pid-file = /home/mysql/mysqldata/3306/mysql.pid
basedir= /usr/local/mysql
datadir= /home/mysql/mysqldata/3306/data
tmpdir=/home/mysql/mysqldata/3306/tmp
open_files_limit = 10240
explicit_defaults_for_timestamp =1
sql_mode=NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO
character_set_server=utf8

#Buffer
max_allowed_packet=256M
max_heap_table_size=256M
net_buffer_length=8k
sort_buffer_size=2M
join_buffer_size=4M
read_buffer_size=2M
read_rnd_buffer_size=16M

#log
log-bin = /home/mysql/mysqldata/3306/binlog/mysql-bin
binlog_cache_size=32M
max_binlog_cache_size=128M
max_binlog_size=128M
binlog_format=mixed
log_output=FILE
log-error=  ../mysql-error.log
slow_query_log=0
slow_query_log_file= ../slow_query.log
general_log= 0
general_log_file=../general_query.log
expire-logs-days= 30

#InnoDB
innodb_data_file_path = ibdata1:2048M:autoextend
innodb_log_file_size = 256M
innodb_log_files_in_group = 3
innodb_buffer_pool_size= 1024M
innodb_lock_wait_timeout=120

[mysql]
no-auto-rehash
prompt = (\u@\h) [\d]>\_
EOF

chown -R mysql:mysql /usr/local/mysql/
chown -R mysql:mysql /mysqldata/
chown -R mysql:mysql /home/mysql

#Running By Mysql
su - mysql -c "echo 'export PATH=/usr/local/mysql/bin:$PATH' >>/home/mysql/.bash_profile"
su - mysql -c "source /home/mysql/.bash_profile"

#Running By Root
echo "===============Start To Initial Database======================"
/usr/local/mysql/bin/mysqld --defaults-file=/home/mysql/mysqldata/3306/my.cnf --initialize --basedir=/usr/local/mysql --datadir=/home/mysql/mysqldata/3306/data
sleep 3

echo "==============Start To setup SSL =================="
/usr/local/mysql/bin/mysql_ssl_rsa_setup --datadir=/home/mysql/mysqldata/3306/data
sleep 3

#Check Error 
checkerr=`grep -w "ERROR]" /home/mysql/mysqldata/3306/mysql-error.log | wc -l`
if [ $checkerr -gt 0 ]
then echo "!!!!!!!!!!!!!!!Found Error when initializing DB,Please have a check !!!!!!!!!!!!!!!"
fi

echo "======================Starting Mysql ========================"
#Running By Mysql --Start Mysql
su - mysql -c "mysqld_safe --defaults-file=/home/mysql/mysqldata/3306/my.cnf &"
#Press Enter 
echo -e "\n"   
sleep 5
rm -rf /tmp/mysql.sock
su - mysql -c "ln -s /home/mysql/mysqldata/3306/mysql.sock /tmp/mysql.sock"

#Check If the db was started fine.
checkport=`netstat -lnt | grep 3306 | wc -l`
if [ $checkport -gt 0 ]
 then 
   echo "Congrats, Mysql Service was started successful!"
  else echo "=======Sorry, Mysql Service was not started, please have a check!=======" 
fi  
}

end() {
echo ""

echo ""
}

##设置显示脚本运行时间##
function start_time()
{
  start_time="$(date +%s)"
  echo "$(date) 开始安装!!"
  echo "$start_time" > /tmp/install_lnmp_runtime
}
function end_time()
{
   end_time="$(date +%s)"
   total_s=$(($end_time - $start_time))
   total_m=$(($total_s/60))
   if [ $total_s -lt 60 ]; then
       time_en="${total_s} 秒"
   else
       time_en="${total_m} 分"
   fi
   echo "$(date) 完成安装"
   echo "运行install_lnmp.sh 所花的时间:${time_en}">/tmp/install_lnmp_runtime
   echo "总共运行时间: ${time_en}"
}

main() {
    start_time
    echo "Installtion MYSQL..."
    install
    end
    end_time
}
main

