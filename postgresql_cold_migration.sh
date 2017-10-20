#!/usr/bin/env bash

##############################################################
# @Filename:    postgresql_cold_migration.sh     
# @Version:     
# @Created:     10.19.2017
# @Author:      
# @Description: 
# @History:     date time modify params xxxx
# @Usage:       ./postgresql_cold_migration.sh 
##############################################################

[ $(whoami) != "root" ] && echo " You must use root account" && exit 1
dir_name=$(cd $(dirname$0) && pwd)
mkdir -p ${dir_name}/postgresql_migration

local_ip=$(/sbin/ifconfig eth0|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:")
date_t=$(date +%Y%m%d)

backup_postgresql(){
	postgresql_data_dir=/srv/smartcare/servicept/bpmpt/data

	su - servicept -c "dbopt -b cmd_stopdb -t all -M abort"


	tar zcvf ${dir_name}/postgresql_migration/postgresql_${local_ip}_${date_t}.tar  -C ${postgresql_data_dir} data

	su - servicept -c "pt_ctl start"
}

migration_shell(){
cat > ${dir_name}/postgresql_migration/postgresql_migration.sh <<EOF
#!/bin/bash
[ \$(whoami) != "root" ] && echo " You must use root account" && exit 1
dir_name=\$(pwd)
postgresql_data_dir=/srv/smartcare/servicept/bpmpt/data

su - servicept -c "dbopt -b cmd_stopdb -t all -M abort"

tar xvf \${dir_name}/postgresql_${local_ip}_${date_t}.tar -C \${postgresql_data_dir}

su - servicept -c "pt_ctl start"
EOF
}
tar_package(){
	tar zcvf postgresql_dump_${local_ip}_${date_t}.tar.gz -C ${dir_name} postgresql_migration
	sha256sum postgresql_dump_${local_ip}_${date_t}.tar.gz > ${dir_name}/postgresql_dump_${local_ip}_${date_t}.hash
	tar zcvf postgresql_migration_${local_ip}_${date_t}.tar.gz postgresql_dump_${local_ip}_${date_t}.tar.gz postgresql_dump_${local_ip}_${date_t}.hash
	rm -rf postgresql_dump_${local_ip}_${date_t}.tar.gz postgresql_dump_${local_ip}_${date_t}.hash postgresql_migration
}
backup_postgresql
migration_shell
tar_package
