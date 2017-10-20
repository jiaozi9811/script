#!/usr/bin/env bash

##############################################################
# @Filename:    mysql_cold_migration.sh     
# @Version:     
# @Created:     10.19.2017
# @Author:       
# @Description: 
# @History:     date time modify params xxxx
# @Usage:       ./mysql_cold_migration.sh 
##############################################################

[ $(whoami) != "root" ] && echo " You must use root account" && exit 1
dir_name=$(cd $(dirname$0) && pwd)

mkdir -p ${dir_name}/mysql_migration

local_ip=$(/sbin/ifconfig eth0|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:")
date_t=$(date +%Y%m%d)

backup_mysql(){
	mysql_data_dir=$(cat /etc/my.cnf|grep datadir|awk -F= '{print $2}')

	system_vesion=$(cat /etc/SuSE-release|grep VERSION|awk '{print $3}')
	if [ ${system_vesion} -le 11 ] ; then
	        /etc/init.d/mysql stop
	elif [ ${system_vesion} -gt 11 ] ;then
	        systemctl stop mysql
	fi

	for i in ${mysql_data_dir}/*
	do
       		if [[ -d $i ]] || [[ -n $(echo $i|grep ib) ]] ; then
          		[[ -z $(echo $i|grep mysql$) ]] && [[ -z $(echo $i|grep performance_schema$) ]] && [[ -z $(echo $i|grep information_schema$) ]] && echo $(basename $i) >> ${dir_name}/mysql_migration/mysql_migration.sh
        	fi
	done

	tar zcvf ${dir_name}/mysql_migration/mysql_${local_ip}_${date_t}.tar  -C ${mysql_data_dir} $(cat ${dir_name}/mysql_migration/mysql_migration.sh)

	if [ ${system_vesion} -le 11 ] ; then
	        /etc/init.d/mysql start
	elif [ ${system_vesion} -gt 11 ] ;then
	        systemctl start mysql
	fi
}

migration_shell(){
cat > ${dir_name}/mysql_migration/mysql_migration.sh <<EOF
#!/bin/bash
[ \$(whoami) != "root" ] && echo " You must use root account" && exit 1
dir_name=\$(pwd)
mysql_data_dir=\$(cat /etc/my.cnf|grep datadir|awk -F= '{print \$2}')

system_vesion=\$(cat /etc/SuSE-release|grep VERSION|awk '{print \$3}')
if [ \${system_vesion} -le 11 ] ; then
	/etc/init.d/mysql stop
elif [ \${system_vesion} -gt 11 ] ;then
	systemctl stop mysql
fi
tar xvf \${dir_name}/mysql_${local_ip}_${date_t}.tar -C \${mysql_data_dir}

if [ \${system_vesion} -le 11 ] ; then
        /etc/init.d/mysql start
elif [ \${system_vesion} -gt 11 ] ;then
        systemctl start mysql
fi
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
