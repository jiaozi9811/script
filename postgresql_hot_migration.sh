#!/usr/bin/env bash

##############################################################
# @Filename:    postgresql_hot_migration.sh     
# @Version:     
# @Created:     10.19.2017
# @Author:       
# @Description: 
# @History:     date time modify params xxxx
# @Usage:       ./postgresql_hot_migration.sh 
##############################################################

[ $(whoami) != "root" ] && echo " You must use root account" && exit 1

dir_name=$(cd $(dirname$0) && pwd)

local_ip=$(/sbin/ifconfig eth0|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:")
date_t=$(date +%Y%m%d)

backup_pg(){
	export LANG=en_US.UTF-8
	export LC_CTYPE="en_US.UTF-8"
	export LC_NUMERIC="en_US.UTF-8"
	export LC_TIME="en_US.UTF-8"
	export LC_COLLATE="en_US.UTF-8"
	export LC_MONETARY="en_US.UTF-8"
	export LC_MESSAGES="en_US.UTF-8"
	export LC_PAPER="en_US.UTF-8"
	export LC_NAME="en_US.UTF-8"
	export LC_ADDRESS="en_US.UTF-8"
	export LC_TELEPHONE="en_US.UTF-8"
	export LC_MEASUREMENT="en_US.UTF-8"
	export LC_IDENTIFICATION="en_US.UTF-8"

	pg_port=2523
	pg_system_user="servicept"
	pg_dbname=pt

	mkdir -p ${dir_name}/pgmigration
	chown -R ${pg_system_user}:${pg_system_user} ${dir_name}/pgmigration

	su - ${pg_system_user} -c "pg_dump -p ${pg_port} ${pg_dbname} -Ft -f ${dir_name}/pgmigration/postgresql_${local_ip}_${date_t}.tar"
}

migration_shell(){
cat > ${dir_name}/pgmigration/pgmigration.sh << EOF
#!/bin/bash

export LANG=en_US.UTF-8
export LC_CTYPE="en_US.UTF-8"
export LC_NUMERIC="en_US.UTF-8"
export LC_TIME="en_US.UTF-8"
export LC_COLLATE="en_US.UTF-8"
export LC_MONETARY="en_US.UTF-8"
export LC_MESSAGES="en_US.UTF-8"
export LC_PAPER="en_US.UTF-8"
export LC_NAME="en_US.UTF-8"
export LC_ADDRESS="en_US.UTF-8"
export LC_TELEPHONE="en_US.UTF-8"
export LC_MEASUREMENT="en_US.UTF-8"
export LC_IDENTIFICATION="en_US.UTF-8"

[ \$(whoami) != "root" ] && echo " You must use root account" && exit 1

pg_port=2523
pg_system_user="servicept"
pg_dbname=pt

dir_name=\$(pwd)

su - \${pg_system_user} -c "pg_restore -p \${pg_port}  -Ft  \${dir_name}/postgresql_${local_ip}_${date_t}.tar"

EOF
}

tar_package(){
	tar zcvf pgmigration_${local_ip}_${date_t}.tar.gz -C ${dir_name} pgmigration

	sha256sum pgmigration_${local_ip}_${date_t}.tar.gz > pgmigration_${local_ip}_${date_t}.hash

	tar zcvf postgresql_migration_${local_ip}_${date_t}.tar.gz pgmigration_${local_ip}_${date_t}.tar.gz pgmigration_${local_ip}_${date_t}.hash

	rm -rf ${dir_name}/pgmigration pgmigration_${local_ip}_${date_t}.hash pgmigration_${local_ip}_${date_t}.tar.gz
}

backup_pg
migration_shell
tar_package
