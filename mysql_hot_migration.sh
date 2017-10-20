#!/usr/bin/env bash

##############################################################
# @Filename:    mysql_hot_migration.sh     
# @Version:     
# @Created:     10.19.2017
# @Author:       
# @Description: 
# @History:     date time modify params xxxx
# @Usage:       ./mysql_hot_migration.sh 
##############################################################

[ $(whoami) != "root" ] && echo " You must use root account" && exit 1

dir_name=$(cd $(dirname$0) && pwd)

local_ip=$(/sbin/ifconfig eth0|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:")
date_t=$(date +%Y%m%d)

backup_mysql(){
	data_path=${dir_name}/mysql_migration/datapath
	mkdir -p ${data_path}
	
	read -s -p "Please Enter Mysql password:" MYSQL_PASSWORD

	mysql_schema=$(mysql -uroot_manager -p${MYSQL_PASSWORD}  -e "show databases;"|sed -n '2,$p'|grep -v mysql|grep -v performance_schema|grep -v information_schema)

	for i in $(echo ${mysql_schema})
	do
		mysqldump -uroot_manager -p${MYSQL_PASSWORD} --databases ${i} --lock-all-tables > ${data_path}/${i}.sql
	done
}

migration_shell(){
cat > ${dir_name}/mysql_migration/mysql_migration.sh << EOF
#!/bin/bash

[ \$(whoami) != "root" ] && echo " You must use root account" && exit 1

dir_name=\$(pwd)

read -s -p "Please Enter Mysql password:" MYSQL_PASSWORD


for i in \${dir_name}/datapath/*
do 
	mysql -uroot_manager -p\${MYSQL_PASSWORD} < \${data_path}/\$i
done
EOF
}
tar_package(){
	tar zcvf mysql_dump_${local_ip}_${date_t}.tar.gz -C ${dir_name} mysql_migration
	sha256sum mysql_dump_${local_ip}_${date_t}.tar.gz > ${dir_name}/mysql_dump_${local_ip}_${date_t}.hash
	tar zcvf mysql_migration_${local_ip}_${date_t}.tar.gz mysql_dump_${local_ip}_${date_t}.tar.gz mysql_dump_${local_ip}_${date_t}.hash
	rm -rf mysql_dump_${local_ip}_${date_t}.tar.gz mysql_dump_${local_ip}_${date_t}.hash mysql_migration
}

backup_mysql
migration_shell
tar_package
